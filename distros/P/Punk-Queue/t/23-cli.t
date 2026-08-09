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

require File::Raw::JSON;
sub jdec { File::Raw::JSON::file_json_decode(join '', @{ $_[0] }) }

# Exit codes and usage.
{
    my ($code, $out) = pq_run([]);
    is($code, 0, 'no args prints usage and exits 0');
    like(join('', @$out), qr/Usage: punk-queue/, 'usage text');

    ($code, $out) = pq_run(['no-such-command']);
    is($code, 2, 'unknown command exits 2');
    like(join('', @$out), qr/unknown command/, 'and says so');

    ($code, $out) = pq_run(['jobs']);
    is($code, 2, 'a command with no --dsn/--app exits 2');
    like(join('', @$out), qr/need --dsn or --app/, 'and says why');

    ($code, $out) = pq_run(['--version']);
    is($code, 0, '--version exits 0');
    like(join('', @$out), qr/punk-queue \d/, 'and prints one');
}

# migrate and migrate --check, the deploy hook.
{
    my $file = queue_file();
    my $dsn  = "dbi:SQLite:dbname=$file";

    # --check against a fresh database must not migrate it as a side
    # effect (auto_migrate fires on job operations, not introspection)
    my ($code, $out) = pq_run(['migrate', '--check', '--dsn', $dsn]);
    is($code, 1, 'migrate --check exits 1 when behind');
    like(join('', @$out), qr/schema 0, latest \d+/, 'and reports both');

    ($code, $out) = pq_run(['migrate', '--dsn', $dsn]);
    is($code, 0, 'migrate exits 0');

    ($code, $out) = pq_run(['migrate', '--check', '--dsn', $dsn]);
    is($code, 0, 'and --check exits 0 once current');
}

# Every read subcommand's --json decodes to the documented shape.
{
    my ($q, $file) = make_queue();
    my $dsn = "dbi:SQLite:dbname=$file";
    $q->task(ok => sub { 1 });
    $q->enqueue('ok', [], queue => 'a');
    $q->enqueue('ok', [], queue => 'b');
    $q->perform($q->dequeue(queues => 'a'));
    my $wid = $q->backend->register_worker(0, { role => 'child' });

    my ($code, $out) = pq_run(['stats', '--json', '--dsn', $dsn]);
    is($code, 0, 'stats --json exits 0');
    my $s = jdec($out);
    is($s->{finished_jobs}, 1, 'stats shape');
    is($s->{total_jobs},    2, 'stats counts');

    ($code, $out) = pq_run(['jobs', '--json', '--dsn', $dsn]);
    is($code, 0, 'jobs --json exits 0');
    my $r = jdec($out);
    is($r->{total}, 2, 'jobs total');
    is(ref $r->{jobs}, 'ARRAY', 'jobs rows');

    ($code, $out) = pq_run(['jobs', '--json', '--state', 'finished',
                            '--dsn', $dsn]);
    is(jdec($out)->{total}, 1, 'the filter vocabulary works from the CLI');

    ($code, $out) = pq_run(['workers', '--json', '--dsn', $dsn]);
    is($code, 0, 'workers --json exits 0');
    is(jdec($out)->{total}, 1, 'workers listed');

    my ($id) = map { $_->{id} } @{ $q->list_jobs->{jobs} };
    ($code, $out) = pq_run(['job', $id, '--json', '--dsn', $dsn]);
    is($code, 0, 'job --json exits 0');
    is(jdec($out)->{id}, $id, 'job shape');

    ($code, $out) = pq_run(['job', '999999', '--dsn', $dsn]);
    is($code, 1, 'no such job exits 1');

    $q->backend->unregister_worker($wid);
}

# reset requires --yes.
{
    my ($q, $file) = make_queue();
    my $dsn = "dbi:SQLite:dbname=$file";
    $q->enqueue('t');

    my ($code, $out) = pq_run(['reset', '--dsn', $dsn]);
    is($code, 2, 'reset without --yes exits 2');
    is($q->stats->{total_jobs}, 1, 'and did nothing');

    ($code) = pq_run(['reset', '--yes', '--dsn', $dsn]);
    is($code, 0, 'reset --yes exits 0');
    is($q->stats->{total_jobs}, 0, 'and emptied the queue');
}

done_testing();
