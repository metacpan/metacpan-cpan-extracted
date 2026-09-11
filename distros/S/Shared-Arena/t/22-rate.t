#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Shared::Arena ();

# A TOKEN BUCKET PER KEY, SHARED BY EVERY WORKER.
#
# The reason this tenant exists is the fork test below: a limit of N enforced
# in a pre-forked pool where each worker keeps its own counter is not a limit
# of N, it is a limit of workers x N, and the number moves when the pool is
# resized. Every other assertion here is about the bucket; that one is about
# the dist.
#
# TIMING IS ASSERTED AS A RANGE, NEVER AS A POINT. A smoker is a loaded machine
# and a sleep is a lower bound on elapsed time and nothing else, so the refill
# tests say "at least this much came back, and not more than the bucket holds".

plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();

my $arena = Shared::Arena->create(size => 2 * 1024 * 1024);

# ---- the bucket ------------------------------------------------------------

{
    # A window long enough that nothing refills while this runs.
    my $rl = $arena->rate('basic', limit => 5, window => 3600, slots => 64);
    ok($rl, 'carved a limiter');

    my $ok = 0;
    $ok += $rl->allow('alice') for 1 .. 5;
    is($ok, 5, 'the first five are allowed');
    is($rl->allow('alice'), 0, 'the sixth is not');
    is($rl->allow('alice'), 0, '...and it stays that way');

    # A different key has its own bucket.
    is($rl->allow('bob'), 1, 'another key is untouched by the first');

    cmp_ok($rl->remaining('alice'), '<', 1, 'alice has less than one request left');
    cmp_ok($rl->remaining('bob'),   '>=', 3, 'bob still has most of his');

    # Asking does not spend.
    my $before = $rl->remaining('bob');
    $rl->remaining('bob') for 1 .. 5;
    is($rl->remaining('bob'), $before, 'remaining() spends nothing');

    cmp_ok($rl->retry_after('alice'), '>', 0, 'alice is told when to come back');
    is($rl->retry_after('bob'), 0, 'bob is not made to wait');
}

# ---- cost ------------------------------------------------------------------

{
    my $rl = $arena->rate('costly', limit => 10, window => 3600, slots => 64);
    is($rl->allow('k', 7), 1, 'an expensive request fits');
    is($rl->allow('k', 7), 0, '...and a second one does not');
    is($rl->allow('k', 3), 1, 'but a cheap one still does');
}

# ---- refill ----------------------------------------------------------------
#
# A full refill takes `window`, so half a window returns about half the bucket.
# The assertion is a RANGE: a loaded smoker may sleep longer than it was asked
# to, which can only return MORE, and the bucket caps that at the limit.

{
    my $rl = $arena->rate('refill', limit => 10, window => 1, slots => 64);
    $rl->allow('x') for 1 .. 10;
    is($rl->allow('x'), 0, 'the bucket is empty');

    select undef, undef, undef, 0.55;

    my $back = $rl->remaining('x');
    cmp_ok($back, '>=', 4,  'about half the bucket refilled after half a window');
    cmp_ok($back, '<=', 10, '...and never more than it holds');

    select undef, undef, undef, 0.75;
    cmp_ok($rl->remaining('x'), '>=', 9.5, 'a full window refills it completely');
    is($rl->allow('x'), 1, 'and it allows again');
}

# ---- THE POINT: one limit across a pre-forked pool -------------------------
#
# Four children, one key, twenty tokens. If each worker kept its own counter
# this would allow eighty.

# Skipped where fork is emulated with threads. A pseudo-process is a thread in
# THIS process, so a child that exits takes the test file's plan with it: every
# assertion above passes, no plan is printed, and the harness calls that a
# FAIL. Shared-Arena 0.01 failed on Strawberry 5.42 for exactly this.
SKIP: {
    skip 'fork is POSIX-only here', 4 if $^O eq 'MSWin32';

    my $KIDS  = 4;
    my $LIMIT = 20;
    my $rl = $arena->rate('pool', limit => $LIMIT, window => 3600, slots => 256);

    pipe(my $rd, my $wr) or die "pipe: $!";
    my @pid;
    for my $k (1 .. $KIDS) {
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if (!$pid) {
            close $rd;
            my $got = 0;
            $got += $rl->allow('shared-key') for 1 .. $LIMIT;
            print {$wr} "$got\n";
            close $wr;
            exit 0;
        }
        push @pid, $pid;
    }
    close $wr;
    my $total = 0;
    while (my $line = <$rd>) { chomp $line; $total += $line }
    waitpid($_, 0) for @pid;

    is($total, $LIMIT,
       "$KIDS workers sharing one key allowed exactly $LIMIT, not " . $KIDS * $LIMIT);

    my %st = $rl->stats;
    is($st{allowed}, $LIMIT, 'the limiter counted them all');
    is($st{denied}, $KIDS * $LIMIT - $LIMIT, 'and counted the refusals');
    is($st{contended}, 0, 'nothing had to fail open');
}

# ---- no boundary to burst across -------------------------------------------
#
# THE BUG A FIXED WINDOW HAS. A fixed window lets a key spend its whole
# allowance at the end of one window and again at the start of the next: 2x the
# limit in an instant, which is what the limit was written to prevent. A bucket
# refills continuously, so no instant exists where twice the limit is available.
#
# Asserted over a whole window: spend the bucket, then hammer it for a window
# and count. A fixed window would hand back the full limit at the boundary.

{
    my $rl = $arena->rate('nobound', limit => 10, window => 1, slots => 64);
    $rl->allow('b') for 1 .. 10;         # empty it

    my $allowed = 0;
    my $end = time + 1;
    while (time < $end) {
        $allowed += $rl->allow('b');
        select undef, undef, undef, 0.01;
    }
    cmp_ok($allowed, '<=', 12,
           'one window returns about one limit, never a doubled burst');
}

# ---- a table too small leaks LOOSER, not tighter ---------------------------

{
    my $rl = $arena->rate('small', limit => 1, window => 3600, slots => 64);
    my $denied = 0;
    for my $i (1 .. 2000) {
        $rl->allow("key$i");
        $denied += ($rl->allow("key$i") ? 0 : 1);
    }
    my %st = $rl->stats;
    cmp_ok($st{evicted}, '>', 0, 'a table smaller than the key set evicts');
    cmp_ok($st{keys}, '<=', $st{slots}, 'and never holds more keys than slots');
    # Whatever it evicted, a key it forgot is allowed again rather than refused
    # for ever: too small must not become an outage.
    is($rl->allow('key1'), 1, 'an evicted key is allowed, not stuck denied');
}

# ---- operator controls -----------------------------------------------------

{
    my $rl = $arena->rate('ops', limit => 3, window => 3600, slots => 64);
    $rl->allow('c') for 1 .. 3;
    is($rl->allow('c'), 0, 'spent');
    $rl->reset('c');
    is($rl->allow('c'), 1, 'reset refills it');

    $rl->allow('d');
    $rl->forget('d');
    my %st = $rl->stats;
    cmp_ok($st{keys}, '>=', 1, 'the table still holds the keys it should');
}

# ---- the shape is the limiter's, not the caller's --------------------------

{
    $arena->rate('shape', limit => 10, window => 60, slots => 64);
    my $again = eval { $arena->rate('shape', limit => 99, window => 60, slots => 64) };
    ok(!$again, 'a caller asking for a different policy is refused');
    like($@, qr/different type or size|already carved/,
         '...and told it is a shape disagreement');
}

# ---- a limiter survives a worker dying inside it ---------------------------
#
# There is nothing to corrupt - a bucket is one word and a hit is one
# compare-and-swap, so a process killed mid-update has either landed it or not.
# This asserts that rather than assuming it.
#
# THE LIMIT IS ENORMOUS AND THE FINAL CHECK USES A FRESH KEY, and both of those
# are the fix for a flaky test rather than decoration. The first version gave
# 'victim' a million tokens and then asked whether 'victim' was still allowed
# after three processes had spent from it as fast as Perl can call a method for
# a fifth of a second. That is six hundred thousand calls on a quick machine and
# more than a million on a quicker one, so the limiter sometimes answered no -
# correctly - and the test failed about one run in three while appearing to be
# about crash safety. It was racing the limit.

SKIP: {
    skip 'needs fork and kill', 4 if $^O eq 'MSWin32';
    my $LIMIT = 100_000_000;
    my $rl = $arena->rate('crash', limit => $LIMIT, window => 3600, slots => 256);

    my @pid;
    for (1 .. 3) {
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if (!$pid) { $rl->allow('victim') while 1; exit 0 }
        push @pid, $pid;
    }
    select undef, undef, undef, 0.2;
    kill 'KILL', $_ for @pid;
    waitpid($_, 0) for @pid;

    my %st = $rl->stats;
    cmp_ok($st{allowed}, '>', 0, 'the killed workers did real work first');

    # A key the dead never touched: this asks whether the LIMITER still works,
    # with nothing to race.
    is($rl->allow('untouched'), 1, 'the limiter still answers after a hard kill');

    # And the victim's own bucket. A word left corrupt by a process dying inside
    # a compare-and-swap would read back as more tokens than the bucket can
    # hold, which is the invariant to assert rather than a count that depends
    # on how fast the machine was.
    my $left = $rl->remaining('victim');
    cmp_ok($left, '<=', $LIMIT, 'the victim bucket holds a sane value, not garbage');
    cmp_ok($left, '<', $LIMIT, '...and shows the spending that really happened');
}

done_testing;
