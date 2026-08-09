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

# End to end: one `punk-queue worker` process, a due cron in the
# database, nothing else. The scheduler inside the supervisor must elect
# itself, fire the occurrence, and the pool's own children must then
# claim and finish the job. t/81 proves the guarantees; this proves the
# plumbing.

sub wait_for {
    my ($check, $timeout) = @_;
    my $deadline = time + ($timeout // 30);
    while (time < $deadline) {
        my $got = $check->();
        return $got if $got;
        select undef, undef, undef, 0.25;
    }
    return undef;
}

{
    my ($q, $file) = make_queue();
    my $dsn = "dbi:SQLite:dbname=$file";
    my $app = task_app($dsn, <<'EOF');
$q->task('cron.mark' => sub { 'marked' });
EOF

    $q->upsert_cron({ name => 'mark', expr => '* * * * *',
                      task => 'cron.mark', args => ['from-cron'] });
    $q->dbh->do('UPDATE pq_crons SET next_run = ? WHERE name = ?',
                undef, int(time / 60) * 60, 'mark');

    my $h = pq_start(['worker', '--app', $app, '-j', 1,
                      '--interval', '0.2']);

    my $job = wait_for(sub {
        my $r = $q->list_jobs(0, 0, { task => 'cron.mark' });
        return undef unless $r->{total};
        my $j = $q->job_info($r->{jobs}[0]{id});
        $j->{state} eq 'finished' ? $j : undef;
    });
    ok($job, 'the supervisor fired the due occurrence and its own pool '
           . 'finished the job') or diag explain $q->list_jobs;
    is_deeply($job->{args}, ['from-cron'], 'with the stored args');
    is($job->{result}, 'marked', 'and the task really ran');

    my $c = $q->cron_info('mark');
    is($c->{last_job}, $job->{id}, 'last_job points at it');
    ok($c->{next_run} > time - 60, 'the schedule moved on');

    my ($code) = pq_finish($h, 'TERM');
    is($code, 0, 'clean shutdown');
    is($q->list_locks(0, 0, { name => 'pq.cron.leader' })->{total}, 0,
       'and the lease was handed back on the way out');
    unlink $app;
}

# --no-scheduler: the pool still drains jobs but never plays leader.
SKIP: {
    skip 'set PUNK_QUEUE_SLOW=1 to run the --no-scheduler window (about 15s)', 3
        unless $ENV{PUNK_QUEUE_SLOW} || $ENV{AUTOMATED_TESTING};

    my ($q, $file) = make_queue();
    my $dsn = "dbi:SQLite:dbname=$file";
    my $app = task_app($dsn, <<'EOF');
$q->task('cron.mark' => sub { 'marked' });
EOF

    $q->upsert_cron({ name => 'mark', expr => '* * * * *',
                      task => 'cron.mark' });
    $q->dbh->do('UPDATE pq_crons SET next_run = ? WHERE name = ?',
                undef, int(time / 60) * 60, 'mark');

    my $h = pq_start(['worker', '--app', $app, '-j', 1,
                      '--interval', '0.2', '--no-scheduler']);

    # ordinary work still flows...
    my $id = $q->enqueue('add', [2, 3]);
    my $done = wait_for(sub {
        my $j = $q->job_info($id);
        $j->{state} eq 'finished' ? $j : undef;
    });
    ok($done, 'a --no-scheduler pool still drains the queue');

    # ...but the due cron sat untouched through an aligned tick or two
    sleep 12;
    is($q->list_jobs(0, 0, { task => 'cron.mark' })->{total}, 0,
       'and the due cron never fired');
    is($q->list_locks(0, 0, { name => 'pq.cron.leader' })->{total}, 0,
       'no lease was ever taken');

    # the 10s pass still beats the supervisor row with the scheduler
    # off - registration was over 12s ago, so a fresh heartbeat proves
    # the parent is beating, not coasting on its boot timestamp
    my ($sup) = grep { $_->{role} eq 'supervisor' }
        @{ $q->list_workers->{workers} };
    ok($sup, 'the supervisor row exists');
    ok(time - $sup->{notified} < 11,
       'and its heartbeat is fresher than the 10s cadence, so it never '
     . 'reads as stale');

    pq_finish($h, 'TERM');
    unlink $app;
}

done_testing();
