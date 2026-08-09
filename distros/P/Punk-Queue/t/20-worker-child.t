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

my $has_hm = eval { require Hyperman; 1 };

# One worker child, driven as a real subprocess through PUNK_QUEUE_ONESHOT,
# over both execution paths. The poll path is forced with
# PUNK_QUEUE_NO_HM_ABI; the loop path runs only when Hyperman is present.

my @paths = (['poll', { PUNK_QUEUE_NO_HM_ABI => 1 }]);
push @paths, ['loop', {}] if $has_hm;

for my $p (@paths) {
    my ($name, $env) = @$p;

    subtest "$name path: one job round-trips" => sub {
        my ($q, $file) = make_queue();
        my $dsn = "dbi:SQLite:dbname=$file";
        my $app = task_app($dsn);
        my $id  = $q->enqueue(add => [2, 3]);

        my ($code, $out) = pq_run(['worker', '--app', $app],
            env => { %$env, PUNK_QUEUE_ONESHOT => 1 });
        is($code, 0, 'worker exited 0') or diag @$out;

        my $j = $q->job_info($id);
        is($j->{state},  'finished', 'job finished');
        is($j->{result}, 5,          'result recorded');
        is($q->list_workers->{total}, 0,
           'the worker row was unregistered on exit');
        unlink $app;
    };

    subtest "$name path: a dying task fails the job, not the worker" => sub {
        my ($q, $file) = make_queue();
        my $app = task_app("dbi:SQLite:dbname=$file");
        my $id = $q->enqueue('boom');

        my ($code, $out) = pq_run(['worker', '--app', $app],
            env => { %$env, PUNK_QUEUE_ONESHOT => 1 });
        is($code, 0, 'worker exited 0 - the die was the job\'s, not ours');
        is($q->job_info($id)->{state}, 'failed', 'job failed');
        like($q->job_info($id)->{result}, qr/task exploded/, 'message kept');
        unlink $app;
    };

    subtest "$name path: unknown task fails the job, worker lives" => sub {
        my ($q, $file) = make_queue();
        my $app = task_app("dbi:SQLite:dbname=$file");
        my $u  = $q->enqueue('never.registered');
        my $ok = $q->enqueue(add => [1, 1]);

        # oneshot claims exactly one; run twice to drain both
        for (1 .. 2) {
            my ($code) = pq_run(['worker', '--app', $app],
                env => { %$env, PUNK_QUEUE_ONESHOT => 1 });
            is($code, 0, "run $_ exited 0");
        }
        like($q->job_info($u)->{result}, qr/no task registered/,
             'the unknown task failed with the reason');
        is($q->job_info($ok)->{state}, 'finished',
           'and the next job still ran');
        unlink $app;
    };

    subtest "$name path: task filter" => sub {
        my ($q, $file) = make_queue();
        my $app = task_app("dbi:SQLite:dbname=$file");
        my $skip = $q->enqueue('boom');
        my $want = $q->enqueue(add => [4, 4]);

        my ($code) = pq_run(['worker', '--app', $app, '-t', 'add'],
            env => { %$env, PUNK_QUEUE_ONESHOT => 1 });
        is($code, 0, 'exited 0');
        is($q->job_info($want)->{state}, 'finished', 'the named task ran');
        is($q->job_info($skip)->{state}, 'inactive',
           'the filtered-out task was not claimed');
        unlink $app;
    };
}

# The in-process API surface, without a subprocess: $q->worker(...)->run
# under ONESHOT drains one job in this very process.
{
    local $ENV{PUNK_QUEUE_ONESHOT}   = 1;
    local $ENV{PUNK_QUEUE_NO_HM_ABI} = 1;
    my ($q) = make_queue();
    $q->task(add => sub { my ($job, $a, $b) = @_; $a + $b });
    my $id = $q->enqueue(add => [5, 6]);

    my $w = $q->worker;
    isa_ok($w, 'Punk::Queue::Worker');
    is($w->run, 1, 'run returned the number of jobs performed');
    ok($w->id, 'the worker knew its row id');
    is($q->job_info($id)->{result}, 11, 'in-process run works');
}

# A future-returning task: the result is awaited via ->get and recorded.
SKIP: {
    skip 'Hyperman required for the future test', 2 unless $has_hm;
    local $ENV{PUNK_QUEUE_ONESHOT} = 1;
    my ($q, $file) = make_queue();
    my $app = task_app("dbi:SQLite:dbname=$file", <<'EOF');
$q->task(future => sub {
    my ($job) = @_;
    my $f = Hyperman::Future->new;
    $f->done('from the future');
    return $f;
});
EOF
    my $id = $q->enqueue('future');
    my ($code, $out) = pq_run(['worker', '--app', $app],
        env => { PUNK_QUEUE_ONESHOT => 1 });
    is($code, 0, 'worker exited 0') or diag @$out;
    is($q->job_info($id)->{result}, 'from the future',
       'a returned future was awaited and its value recorded');
    unlink $app;
}

done_testing();
