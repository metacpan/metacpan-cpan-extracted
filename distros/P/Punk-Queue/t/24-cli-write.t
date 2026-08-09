#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PQTest;
use PQSpawn;

plan skip_all => 'DBI and DBD::SQLite required' unless has_dbd();

# The write half of the CLI, all of it from --dsn alone: the rule is that
# a write action existing only in the web UI is a write action you cannot
# perform during an incident.

# enqueue round-trips through job, including the JSON-vs-string rule.
{
    my ($q, $file) = make_queue();
    my $dsn = "dbi:SQLite:dbname=$file";

    my ($code, $out) = pq_run(['enqueue', 'mail.send',
                               '{"to":"a@b.c"}', 'plain-string', '42',
                               '-q', 'mail', '-p', '5',
                               '--attempts', '3', '--delay', '60',
                               '--dsn', $dsn]);
    is($code, 0, 'enqueue exits 0');
    my ($id) = join('', @$out) =~ /^(\d+)$/m;
    ok($id, 'and prints the id');

    my $j = $q->job_info($id);
    is($j->{queue},    'mail', 'queue option');
    is($j->{priority}, 5,      'priority option');
    is($j->{attempts}, 3,      'attempts option');
    ok($j->{delayed} > $j->{created}, 'delay option');

    # the argument rule: JSON parses as JSON, everything else is a string
    is_deeply($j->{args}[0], { to => 'a@b.c' }, 'JSON arg decoded');
    is($j->{args}[1], 'plain-string', 'non-JSON arg kept as a string');
    is($j->{args}[2], 42, 'a bare number is JSON');

    # --json passes the whole array unambiguously
    ($code, $out) = pq_run(['enqueue', 't', '--json', '["x",{"y":1}]',
                            '--dsn', $dsn]);
    is($code, 0, '--json form exits 0');
    my ($id2) = join('', @$out) =~ /^(\d+)$/m;
    is_deeply($q->job_info($id2)->{args}, ['x', { y => 1 }],
              'the array arrived intact');

    ($code, $out) = pq_run(['enqueue', 't', '--json', 'not json',
                            '--dsn', $dsn]);
    is($code, 2, 'malformed --json exits 2');

    ($code, $out) = pq_run(['enqueue', 'bad name', '--dsn', $dsn]);
    is($code, 1, 'an invalid task name exits 1');
    like(join('', @$out), qr/invalid task name/, 'with the reason');
}

# job --fail, --retry, --remove produce the same transitions as the API.
{
    my ($q, $file) = make_queue();
    my $dsn = "dbi:SQLite:dbname=$file";
    my $id = $q->enqueue('t');
    $q->dequeue;                            # active

    my ($code, $out) = pq_run(['job', $id, '--fail', 'stuck',
                               '--dsn', $dsn]);
    is($code, 0, '--fail on an active job exits 0');
    is($q->job_info($id)->{state}, 'failed', 'and it failed');
    is($q->job_info($id)->{result}, 'stuck', 'with the reason');

    ($code, $out) = pq_run(['job', $id, '--retry',
                            '--delay', '120', '--priority', '9',
                            '--dsn', $dsn]);
    is($code, 0, '--retry exits 0');
    my $j = $q->job_info($id);
    is($j->{state},    'inactive', 'inactive again');
    is($j->{retries},  1,          'retries bumped');
    is($j->{priority}, 9,          'priority override');
    ok($j->{delayed} - $j->{retried} >= 119, 'delay override');

    ($code, $out) = pq_run(['job', $id, '--remove', '--dsn', $dsn]);
    is($code, 0, '--remove exits 0');
    ok(!defined $q->job_info($id), 'gone');

    # exclusivity and failure modes
    ($code, $out) = pq_run(['job', '1', '--retry', '--remove',
                            '--dsn', $dsn]);
    is($code, 2, 'exclusive write options exit 2');

    my $act = $q->enqueue('t');
    $q->dequeue;
    ($code, $out) = pq_run(['job', $act, '--remove', '--dsn', $dsn]);
    is($code, 1, 'removing an active job exits 1');
    like(join('', @$out), qr/retry it first/, 'and explains the way out');
}

# Multiple ids in one call - the CLI equivalent the phase-8 UI's bulk
# actions gate on.
{
    my ($q, $file) = make_queue();
    my $dsn = "dbi:SQLite:dbname=$file";
    $q->task(boom => sub { die "x\n" });
    my @ids = map { $q->enqueue('boom') } 1 .. 3;
    $q->perform($q->dequeue) for 1 .. 3;
    is($q->stats->{failed_jobs}, 3, 'three failed jobs');

    my ($code, $out) = pq_run(['job', @ids, '--retry', '--dsn', $dsn]);
    is($code, 0, 'job ID ID ID --retry exits 0');
    is($q->stats->{inactive_jobs}, 3, 'all three retried');

    # a partial failure: one id exists, one does not -> exit 1, but the
    # real one is still acted on
    ($code, $out) = pq_run(['job', $ids[0], '999999', '--remove',
                            '--dsn', $dsn]);
    is($code, 1, 'a missing id in the batch exits 1');
    ok(!defined $q->job_info($ids[0]), 'the present id was still removed');
}

# The log surface: a finished job's whole story from the shell.
{
    my ($q, $file) = make_queue();
    my $dsn = "dbi:SQLite:dbname=$file";
    $q->task(chatty => sub { $_[0]->log('half way'); 'done' });
    my $id = $q->enqueue('chatty');
    $q->perform($q->dequeue);

    my ($code, $out) = pq_run(['job', $id, '--log', '--dsn', $dsn]);
    is($code, 0, 'job --log exits 0');
    my $text = join '', @$out;
    like($text, qr/info\s+claimed by worker/, 'the claim row prints');
    like($text, qr/info\s+half way/,          'the task row prints');
    like($text, qr/info\s+finished/,          'the finish row prints');

    ($code, $out) = pq_run(['job', $id, '--log', '--json', '--dsn', $dsn]);
    is($code, 0, 'job --log --json exits 0');
    like(join('', @$out), qr/"message":"half way"/, 'and emits the rows');
}

# The cron surface: anything the admin UI's crons page can do, the CLI can
# do - list, fire now, pause, resume - plus `cron next`, which needs no
# database at all.
{
    my ($q, $file) = make_queue();
    my $dsn = "dbi:SQLite:dbname=$file";
    $q->upsert_cron({ name => 'nightly', expr => '0 3 * * *',
                      task => 'report', args => [7], queue => 'mail',
                      priority => 2, attempts => 3 });

    my ($code, $out) = pq_run(['crons', '--dsn', $dsn]);
    is($code, 0, 'crons exits 0');
    like(join('', @$out), qr/nightly.*0 3 \* \* \*.*yes/s,
         'lists the cron, enabled');

    ($code, $out) = pq_run(['cron', 'run', 'nightly', '--dsn', $dsn]);
    is($code, 0, 'cron run exits 0');
    my ($id) = join('', @$out) =~ /job (\d+)/;
    my $j = $q->job_info($id);
    is($j->{task}, 'report', 'run enqueued the cron task');
    is_deeply($j->{args}, [7], 'with its stored args');
    is($j->{queue}, 'mail', 'on its queue');
    is($q->cron_info('nightly')->{next_run},
       Punk::Queue::Cron->next_after('0 3 * * *', time),
       'and never advanced the schedule');

    ($code, $out) = pq_run(['cron', 'disable', 'nightly', '--dsn', $dsn]);
    is($code, 0, 'cron disable exits 0');
    ok(!$q->cron_info('nightly')->{enabled}, 'disabled in the row');

    ($code, $out) = pq_run(['cron', 'enable', 'nightly', '--dsn', $dsn]);
    is($code, 0, 'cron enable exits 0');
    ok($q->cron_info('nightly')->{enabled}, 're-enabled');

    ($code, $out) = pq_run(['cron', 'run', 'missing', '--dsn', $dsn]);
    is($code, 1, 'an unknown cron exits 1');

    # no database anywhere near this one
    ($code, $out) = pq_run(['cron', 'next', '*/15 * * * *', '--count', '3']);
    is($code, 0, 'cron next exits 0 without --dsn');
    is(scalar(grep { /^\d{4}-/ } @$out), 3, 'and prints three occurrences');

    ($code, $out) = pq_run(['cron', 'next', 'bogus']);
    is($code, 1, 'a bad expression exits 1');
}

done_testing();
