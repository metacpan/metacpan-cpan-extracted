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

# The degradation matrix: PUNK_QUEUE_NO_HM_ABI forces the poll(2) path,
# and the outcomes must be identical to the loop path - same states, same
# results, no crash. On Pg the poll path still carries the notify fd, so
# even fully degraded the wakeup works.

my %env = (PUNK_QUEUE_NO_HM_ABI => 1);

# SQLite, degraded: a mixed batch drains to the same outcomes.
{
    my ($q, $file) = make_queue();
    my $app = task_app("dbi:SQLite:dbname=$file");
    my $ok    = $q->enqueue(add  => [2, 3]);
    my $bad   = $q->enqueue('boom', [], attempts => 1);
    my $never = $q->enqueue('not.registered', [], attempts => 1);

    my $h = pq_start(['worker', '--app', $app], env => \%env);
    my $deadline = time + 30;
    while (time < $deadline) {
        my $s = $q->stats;
        last if $s->{inactive_jobs} == 0 && $s->{active_jobs} == 0;
        select undef, undef, undef, 0.2;
    }

    is($q->job_info($ok)->{state},  'finished', 'good job finished');
    is($q->job_info($ok)->{result}, 5,          'with its result');
    is($q->job_info($bad)->{state}, 'failed',   'dying job failed');
    is($q->job_info($never)->{state}, 'failed', 'unknown task failed');
    like($q->job_info($never)->{result}, qr/no task registered/,
         'with the reason');

    my ($code, $out) = pq_finish($h, 'TERM');
    is($code, 0, 'clean exit on the poll path');
    unlike(join('', @$out), qr/Segmentation|Bus error|core dumped/i,
           'no crash');
    unlink $app;
}

# Pg, degraded: same outcomes, and NOTIFY still wakes via the pollfd.
SKIP: {
    skip 'set PUNK_QUEUE_PG_DSN to run the Pg half', 5 unless has_pg();

    my $q = make_pg_queue();
    my $app = task_app(pg_dsn());

    my $h = pq_start(['worker', '--app', $app, '--interval', '60'],
                     env => \%env);
    my $deadline = time + 15;
    while (time < $deadline) {
        last if $q->list_workers->{total} > 0;
        select undef, undef, undef, 0.1;
    }
    select undef, undef, undef, 0.5;

    my $ok  = $q->enqueue(add => [4, 4]);
    my $bad = $q->enqueue('boom', [], attempts => 1);
    $deadline = time + 15;
    while (time < $deadline) {
        last if ($q->job_info($ok)->{state} eq 'finished'
              && $q->job_info($bad)->{state} eq 'failed');
        select undef, undef, undef, 0.05;
    }

    is($q->job_info($ok)->{state},  'finished', 'good job finished');
    is($q->job_info($ok)->{result}, 8,          'with its result');
    is($q->job_info($bad)->{state}, 'failed',   'dying job failed');

    my ($code, $out) = pq_finish($h, 'TERM');
    is($code, 0, 'clean exit');
    unlike(join('', @$out), qr/Segmentation|Bus error|core dumped/i,
           'no crash');
    unlink $app;
}

done_testing();
