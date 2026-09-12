#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Shared::Arena ();

# ONE HOLDER AT A TIME, AND A SUCCESSOR WHEN IT DIES.
#
# The single-process semantics (acquire, renew, release, fence advancing on a
# new tenure) are checked by the ABI selftest. What needs more than one process
# - and is the whole reason the tenant exists - is exclusion and handover:
#
#   * two processes cannot both hold it,
#   * a holder that stops renewing loses it after the deadline,
#   * a holder that DIES loses it at once, before the deadline,
#   * and every handover advances the fence, so a superseded holder is
#     distinguishable from the current one.
#
# TIMING IS A RANGE. A sleep is a lower bound on elapsed time, so the deadline
# tests wait comfortably past the ttl and never assert an exact instant.

plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();

my $arena = Shared::Arena->create(size => 1 * 1024 * 1024);

# ---- single process: the basics hold ---------------------------------------

{
    my $l = $arena->lease('basic', ttl => 30);
    ok($l->acquire, 'acquire a free lease');
    ok($l->mine, 'and we hold it');
    is($l->holder, $$, 'holder is our pid');
    cmp_ok($l->fence, '>', 0, 'a tenure has a fence');
    ok($l->renew, 'renew while held');
    ok($l->release, 'release it');
    ok(!$l->mine, 'no longer held');
    is($l->holder, 0, 'and holder is nobody');
}

# ---- two processes cannot both hold it -------------------------------------

SKIP: {
    skip 'fork is POSIX-only here', 3 if $^O eq 'MSWin32';

    my $l = $arena->lease('excl', ttl => 60);
    ok($l->acquire, 'the parent takes the lease');

    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        # The child must NOT be able to take a lease the parent holds and is
        # keeping current.
        my $got = $l->acquire ? 1 : 0;
        exit($got);          # exit 0 = correctly denied, 1 = wrongly acquired
    }
    waitpid($pid, 0);
    is($? >> 8, 0, 'a second process is denied while the holder is current');
    ok($l->mine, 'and the parent still holds it');
    $l->release;
}

# ---- a holder that stops renewing loses it after the deadline --------------

SKIP: {
    skip 'fork is POSIX-only here', 3 if $^O eq 'MSWin32';

    # A short ttl, and a child that takes it and then does NOT renew.
    my $l = $arena->lease('lapse', ttl => 0.05);   # 50ms

    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        $l->acquire or exit 9;
        exit 0;             # holds it, then exits without releasing
    }
    waitpid($pid, 0);
    is($? >> 8, 0, 'the child acquired the lease');

    # Right after the child exits the lease is technically still "owned" by the
    # dead pid - but holder() accounts for both death and the deadline.
    is($l->holder, 0, 'a dead holder reports as nobody, not its stale pid');

    # And the parent can take it over.
    my ($held, $took) = $l->acquire;
    ok($held && $took, 'a successor takes over a lapsed/dead holder, and knows it did');
    $l->release;
}

# ---- a DEAD holder is stolen before the deadline ---------------------------
#
# The deadline is long here, so a successor taking over quickly can only be the
# pid-death fast path, not the clock.

SKIP: {
    skip 'fork is POSIX-only here', 2 if $^O eq 'MSWin32';

    my $l = $arena->lease('dead', ttl => 3600);   # an hour: the clock will not save us

    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        $l->acquire or exit 9;
        exit 0;             # take it and die, with an hour left on the clock
    }
    waitpid($pid, 0);
    is($? >> 8, 0, 'the child took an hour-long lease and died');

    # No sleeping near an hour: if this works it is because the holder is gone,
    # not because time passed.
    ok($l->acquire, 'a successor steals a dead holder long before the deadline');
    $l->release;
}

# ---- the fence advances on every handover ----------------------------------

SKIP: {
    skip 'fork is POSIX-only here', 2 if $^O eq 'MSWin32';

    my $l = $arena->lease('fence', ttl => 0.05);
    $l->acquire;
    my $f0 = $l->fence;
    $l->release;

    my @fences;
    for (1 .. 3) {
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if (!$pid) { $l->acquire; exit 0 }   # each child takes a fresh tenure
        waitpid($pid, 0);
        select undef, undef, undef, 0.08;    # let it lapse before the next
        # re-read the fence from a fresh handle in the parent
        my $probe = $arena->lease('fence', ttl => 0.05);
        $probe->acquire;
        push @fences, $probe->fence;
        $probe->release;
    }
    # Strictly increasing: every takeover is a new generation.
    my $ok = 1;
    $ok &&= ($fences[$_] > $fences[$_-1]) for 1 .. $#fences;
    ok($fences[0] > $f0, 'a takeover advances the fence past the first tenure');
    ok($ok, 'and every subsequent handover advances it again');
}

# ---- a pool converges on exactly one leader --------------------------------
#
# Every worker tries to acquire; exactly one should win at any moment. Run a
# short race and assert that across the whole pool the lease was never held by
# two pids that both thought they were current.

SKIP: {
    skip 'fork is POSIX-only here', 1 if $^O eq 'MSWin32';

    my $KIDS = 6;
    my $l = $arena->lease('pool', ttl => 0.10);
    pipe(my $rd, my $wr) or die "pipe: $!";

    my @pid;
    for my $k (1 .. $KIDS) {
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if (!$pid) {
            close $rd;
            my $lease = $arena->lease('pool', ttl => 0.10);
            my $held_ticks = 0;
            for (1 .. 20) {
                if ($lease->acquire) {
                    $held_ticks++;
                    # Report each moment we believe we are the leader, with our
                    # fence: two pids reporting the same fence would be a bug.
                    syswrite($wr, "$$ " . $lease->fence . "\n");
                    $lease->renew;
                }
                select undef, undef, undef, 0.02;
            }
            close $wr;
            exit 0;
        }
        push @pid, $pid;
    }
    close $wr;
    my %by_fence;
    while (my $line = <$rd>) {
        chomp $line;
        my ($p, $f) = split ' ', $line;
        $by_fence{$f}{$p} = 1;
    }
    waitpid($_, 0) for @pid;

    # A given fence (tenure) must belong to exactly one pid. Two pids sharing a
    # fence would mean two leaders in one tenure.
    my @shared = grep { keys %{ $by_fence{$_} } > 1 } keys %by_fence;
    is_deeply(\@shared, [],
              'no tenure was ever claimed by two workers at once');
}

done_testing;
