#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Shared::Arena ();

# HOW OFTEN, IN FIXED SPACE.
#
# The contract is asymmetric and the asymmetry is the whole point: a count-min
# sketch may answer HIGH and must never answer LOW. Collisions can only ever
# have added, so a heavy hitter can never hide behind one - it can only make a
# quiet key look busier than it is.
#
# The first test is therefore the one that matters: for every key, whatever the
# collisions did, the estimate is at least the truth. That has to hold exactly
# and always, not usually.

plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();

my $arena = Shared::Arena->create(size => 16 * 1024 * 1024);

# ---- THE GUARANTEE ---------------------------------------------------------

{
    my $cms = $arena->countmin('exact', error => 0.001, confidence => 0.99);
    ok($cms, 'carved a sketch');
    cmp_ok($cms->rows, '>=', 1, 'it has rows');
    cmp_ok($cms->width, '>=', 64, 'and a width');

    my %truth;
    for my $i (1 .. 500) {
        my $key = "key$i";
        my $n   = ($i % 17) + 1;
        $cms->add($key) for 1 .. $n;
        $truth{$key} = $n;
    }

    my $low = 0;
    my $exact = 0;
    for my $key (sort keys %truth) {
        my $got = $cms->estimate($key);
        $low++   if $got <  $truth{$key};
        $exact++ if $got == $truth{$key};
    }
    is($low, 0, 'NOT ONE key was underestimated, out of 500');
    cmp_ok($exact, '>', 450, 'and nearly all of them were exact');

    my %s = $cms->stats;
    my $total = 0;
    $total += $_ for values %truth;
    is($s{total}, $total, 'the sketch counted everything that went in');
    is($s{adds}, $total, 'and counted the calls');
}

# ---- the error is a fraction of the TOTAL, not of the key ------------------

{
    # A deliberately cramped sketch, so collisions are certain and the bound is
    # the only thing standing between the answer and nonsense.
    my $cms = $arena->countmin('cramped', rows => 3, width => 64);
    $cms->add("k$_") for 1 .. 5000;

    my %s = $cms->stats;
    is($s{total}, 5000, 'everything was counted');
    cmp_ok($s{error}, '>', 0, 'a cramped sketch admits to an error bound');

    my $over = 0;
    for my $i (1 .. 200) {
        my $got = $cms->estimate("k$i");
        cmp_ok($got, '>=', 1, "k$i is never lost") if $i <= 3;
        $over++ if $got > 1 + $s{error};
    }
    is($over, 0, 'no estimate exceeded the truth by more than the bound');
}

# ---- a heavy hitter stands out ---------------------------------------------

{
    my $cms = $arena->countmin('heavy', error => 0.001);
    $cms->add("noise$_") for 1 .. 20_000;
    $cms->add('loud', 5_000);

    my $loud = $cms->estimate('loud');
    cmp_ok($loud, '>=', 5_000, 'the heavy hitter is not underestimated');
    my %s = $cms->stats;
    cmp_ok($loud, '<=', 5_000 + $s{error},
           '...and is within the bound of the truth');
    cmp_ok($loud, '>', $cms->estimate('noise1') * 100,
           '...and towers over the noise, which is what it is for');
}

# ---- add() hands back the new estimate -------------------------------------

{
    my $cms = $arena->countmin('running', error => 0.001);
    my $last = 0;
    for (1 .. 10) {
        my $now = $cms->add('x');
        cmp_ok($now, '>', $last, 'add returns a running estimate') if $_ <= 3;
        $last = $now;
    }
    is($last, 10, 'which after ten adds is ten');
    is($cms->estimate('x'), 10, 'and estimate agrees without adding');
}

# ---- shared across a pre-forked pool ---------------------------------------
#
# The reason this lives in an arena: four workers counting the same key must
# produce one number, not four.

# Skipped where fork is emulated with threads: a pseudo-process is a thread in
# THIS process, so a child that exits takes the file's plan with it.
SKIP: {
    skip 'fork is POSIX-only here', 2 if $^O eq 'MSWin32';

    my $KIDS = 4;
    my $PER  = 250;
    my $cms = $arena->countmin('pool', error => 0.0001);

    my @pid;
    for my $k (1 .. $KIDS) {
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if (!$pid) {
            $cms->add('hot') for 1 .. $PER;
            exit 0;
        }
        push @pid, $pid;
    }
    waitpid($_, 0) for @pid;

    is($cms->estimate('hot'), $KIDS * $PER,
       "$KIDS workers counting one key agree on " . $KIDS * $PER);
    my %s = $cms->stats;
    is($s{total}, $KIDS * $PER, 'and the total matches');
}

# ---- reset -----------------------------------------------------------------

{
    my $cms = $arena->countmin('clearable', error => 0.01);
    $cms->add('a', 100);
    cmp_ok($cms->estimate('a'), '>=', 100, 'counted');
    $cms->reset;
    is($cms->estimate('a'), 0, 'reset forgets everything');
    my %s = $cms->stats;
    is($s{total}, 0, '...including the total');
}

# ---- the shape is the sketch's, not the caller's ---------------------------

{
    $arena->countmin('shape', rows => 4, width => 256);
    my $again = eval { $arena->countmin('shape', rows => 8, width => 256) };
    ok(!$again, 'a caller asking for a different shape is refused');
    like($@, qr/different type or size|already carved/,
         '...and told it is a shape disagreement');
}

# ---- a worker dying inside an add cannot corrupt it ------------------------
#
# An add is one fetch-add per row and there is nothing to roll back. A process
# killed part way through has counted its key in some rows and not others,
# which reads back as a LOWER estimate for that key - never a corrupt sketch,
# and never a wrong answer for anybody else.

SKIP: {
    skip 'needs fork and kill', 3 if $^O eq 'MSWin32';
    my $cms = $arena->countmin('crash', error => 0.001);
    $cms->add('bystander', 1000);

    my @pid;
    for (1 .. 3) {
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if (!$pid) { $cms->add('victim') while 1; exit 0 }
        push @pid, $pid;
    }
    select undef, undef, undef, 0.2;
    kill 'KILL', $_ for @pid;
    waitpid($_, 0) for @pid;

    cmp_ok($cms->estimate('victim'), '>', 0, 'the killed workers counted first');
    cmp_ok($cms->estimate('bystander'), '>=', 1000,
           'and a key they never touched is untouched');
    is($cms->add('after', 5), 5, 'the sketch still counts after a hard kill');
}

done_testing;
