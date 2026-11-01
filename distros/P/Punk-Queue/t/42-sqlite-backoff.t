#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Time::HiRes ();
use PQTest;
use PQSpawn;

plan skip_all => q{needs fork, which a Windows perl only emulates} if $^O eq q{MSWin32};
plan skip_all => 'DBI and DBD::SQLite required' unless has_dbd();

# The SQLite wakeup story is jittered polling, and this is its budget
# test: four children against one file, 200 jobs, everything drains
# within a sane wall clock and every child gets work. The jitter's whole
# job is breaking the lockstep that would otherwise have four processes
# hammering BEGIN IMMEDIATE at the same instant.
{
    my ($q, $file) = make_queue();
    # each job costs ~20ms, so the drain takes long enough for the whole
    # pool to participate - 200 instant jobs were gone before children
    # three and four had even booted, which tested startup, not starvation
    my $app = task_app("dbi:SQLite:dbname=$file", <<'EOF');
$q->task(msleep => sub { select undef, undef, undef, 0.02; 1 });
EOF

    my $h = pq_start(['worker', '--app', $app, '-j', '4'],
                     env => { PUNK_QUEUE_NO_HM_ABI => 1 });

    # all four children up before any work exists
    my $deadline = time + 60;
    while (time < $deadline) {
        last if grep({ $_->{role} eq 'child' }
                     @{ $q->list_workers->{workers} }) == 4;
        select undef, undef, undef, 0.1;
    }

    my $t0 = Time::HiRes::time();
    $q->enqueue('msleep') for 1 .. 200;

    $deadline = time + 60;
    while (time < $deadline) {
        last if $q->stats->{finished_jobs} == 200;
        select undef, undef, undef, 0.2;
    }
    my $took = Time::HiRes::time() - $t0;

    is($q->stats->{finished_jobs}, 200, 'all 200 jobs drained');
    ok($took < 60, sprintf 'inside the budget (%.1fs)', $took);

    # every child claimed: the finished rows carry their claimer's id
    my $claimers = $q->dbh->selectcol_arrayref(
        "SELECT DISTINCT worker FROM pq_jobs WHERE state = 'finished'");
    is(scalar @$claimers, 4, 'no child starved - all four claimed work')
        or diag "claimers: @$claimers";

    my ($code) = pq_finish($h, 'TERM');
    is($code, 0, 'clean shutdown');
    unlink $app;
}

# The delayed-job horizon: a worker with a long interval still starts a
# delayed job on time, because the sleep clamps to the horizon. This is
# what makes the 5s default interval safe.
{
    my ($q, $file) = make_queue();
    my $app = task_app("dbi:SQLite:dbname=$file");

    my $h = pq_start(['worker', '--app', $app, '--interval', '30'],
                     env => { PUNK_QUEUE_NO_HM_ABI => 1 });

    # The pool is up and idle before the delayed job exists, because the
    # lag below has to measure the wakeup and nothing else. Enqueueing
    # first made a slow box's worker boot part of the measurement: three
    # seconds of delay were spent starting a perl, the job was already
    # overdue when the first poll ran, and a healthy clamp read as late.
    my $lim = time + 60;
    while (time < $lim) {
        last if grep { $_->{role} eq 'child' }
                @{ $q->list_workers->{workers} };
        select undef, undef, undef, 0.1;
    }

    my $id = $q->enqueue(add => [3, 3], delay => 3);

    $lim = Time::HiRes::time() + 60;
    my $done_at;
    while (Time::HiRes::time() < $lim) {
        if ($q->job_info($id)->{state} eq 'finished') {
            $done_at = Time::HiRes::time();
            last;
        }
        select undef, undef, undef, 0.05;
    }
    ok($done_at, 'the delayed job ran');
    my $info = $q->job_info($id);
    my $lag = $info->{started} - $info->{delayed};
    ok($lag >= 0, 'not early');
    # half the interval, not a stopwatch: the claim is that the sleep was
    # cut short, and anything under 15s on a 30s interval proves it
    # whatever the box was doing at the time.
    ok($lag < 15, sprintf 'and not a full interval late (%.2fs lag) - '
                        . 'the horizon clamp woke the worker', $lag);

    my ($code) = pq_finish($h, 'TERM');
    is($code, 0, 'clean shutdown');
    unlink $app;
}

done_testing();
