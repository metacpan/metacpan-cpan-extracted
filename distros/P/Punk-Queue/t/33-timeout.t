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

plan skip_all => 'DBI and DBD::SQLite required' unless has_dbd();

# The three timeout layers, tested separately because they guarantee
# different things - and the docs are explicit that only the third is a
# guarantee.

# Layer 1: alarm, off-loop. A sleeping Perl task is interrupted between
# opcodes and the die is caught like any task failure.
{
    local $ENV{PUNK_QUEUE_NO_HM_ABI} = 1;
    my ($q) = make_queue();
    $q->task(snooze => sub { sleep 30; 'woke' });
    my $id = $q->enqueue('snooze', [], timeout => 1, attempts => 1);

    my $t0 = Time::HiRes::time();
    ok(!$q->perform($q->dequeue), 'perform reported failure');
    my $took = Time::HiRes::time() - $t0;

    my $j = $q->job_info($id);
    is($j->{state}, 'failed', 'the job failed');
    like($j->{result}, qr/job timed out/, 'with the timeout message');
    ok($took < 10, "and promptly, not after the sleep ($took)");
    is($ENV{PUNK_QUEUE_NO_HM_ABI}, 1, '(off-loop path)');
}

# The alarm is cleared and restored afterwards: a fast job under the same
# worker must not inherit a stale timer.
{
    local $ENV{PUNK_QUEUE_NO_HM_ABI} = 1;
    my ($q) = make_queue();
    my $fired = 0;
    local $SIG{ALRM} = sub { $fired = 1 };
    $q->task(quick => sub { 'done' });
    my $id = $q->enqueue('quick', [], timeout => 1);
    ok($q->perform($q->dequeue), 'a fast job under a timeout succeeds');
    sleep 2;
    is($fired, 0, 'no stale alarm fired afterwards');
    is(ref $SIG{ALRM}, 'CODE', 'and the previous handler was restored');
}

# Layer 2: the loop timer fails a returned future. Only meaningful with
# Hyperman present.
SKIP: {
    skip 'Hyperman required for the loop layer', 4
        unless eval { require Hyperman; 1 };

    my ($q, $file) = make_queue();
    my $app = task_app("dbi:SQLite:dbname=$file", <<'EOF');
$q->task(hang => sub {
    my ($job) = @_;
    return Hyperman::Future->new;      # never settled
});
EOF
    my $id = $q->enqueue('hang', [], timeout => 1, attempts => 1);

    my $t0 = Time::HiRes::time();
    my ($code, $out) = pq_run(['worker', '--app', $app],
        env => { PUNK_QUEUE_ONESHOT => 1 });
    my $took = Time::HiRes::time() - $t0;

    is($code, 0, 'the worker survived the hung future') or diag @$out;
    my $j = $q->job_info($id);
    is($j->{state}, 'failed', 'the job failed');
    like($j->{result}, qr/job timed out/, 'via the loop timer');
    ok($took < 15, "without waiting forever ($took)");
    unlink $app;
}

# Layer 3: the supervisor's SIGKILL - the only hard guarantee. The task
# defeats the alarm layer deliberately (a task is allowed to be hostile;
# the parent is not allowed to care).
{
    my ($q, $file) = make_queue();
    my $app = task_app("dbi:SQLite:dbname=$file", <<'EOF');
$q->task(hostile => sub {
    local $SIG{ALRM} = 'IGNORE';       # defeats layer 1
    sleep 1 while 1;                    # never returns
});
EOF
    my $id = $q->enqueue('hostile', [], timeout => 0.5, attempts => 1);

    my $h = pq_start(['worker', '--app', $app, '-j', '1'],
                     env => { PUNK_QUEUE_NO_HM_ABI => 1 });

    # kill threshold is timeout * 1.5 + 5 = 5.75s; allow slack
    my $deadline = time + 30;
    my $j;
    while (time < $deadline) {
        $j = $q->job_info($id);
        last if $j && $j->{state} eq 'failed';
        select undef, undef, undef, 0.25;
    }
    is($j->{state}, 'failed', 'the parent failed the job');
    like($j->{result}, qr/worker was killed/, 'and said what it did');

    # the pool recovered: a fresh child ran the next job
    $q->task(ok => sub { 1 });   # registry only matters in the child's copy
    my $ok = $q->enqueue('add', [], queue => 'default');
    $deadline = time + 20;
    while (time < $deadline) {
        last if ($q->job_info($ok)->{state} // '') ne 'inactive';
        select undef, undef, undef, 0.25;
    }
    isnt($q->job_info($ok)->{state}, 'inactive',
         'a respawned child claimed the next job');

    my ($code) = pq_finish($h, 'TERM');
    is($code, 0, 'clean shutdown after a hard kill');
    unlink $app;
}

done_testing();
