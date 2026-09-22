#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Shared::Arena ();

# CARVING THE REGISTRY FROM SEVERAL PROCESSES AT ONCE.
#
# The registry append is a resource every carver shares, and the stripe lock
# does not protect it: that lock is keyed on the NAME, so it serialises two
# carves of the same name and does nothing whatever for two carves of different
# ones. Claiming the slot by reading `reg_used` and storing `idx + 1` a few
# instructions later therefore let two processes take the SAME index. Both
# filled it in, the second overwrote the first, and both callers were told they
# had succeeded - with the loser's arena space still spent.
#
# THE ASSERTION IS THE COUNT, AND IT HAS TO BE CONCURRENT. Carving the same
# 4000 names serially passes with the bug in place, which is why the serial arm
# is here too: it proves the test data fits, so a failure in the second arm is
# the race and not an arena that ran out of room.
#
# Measured with the read-then-write claim: 3263 of 4000. It is not a rare
# window.

plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();
plan skip_all => 'needs fork' if $^O eq 'MSWin32';

my $KIDS = 8;
my $PER  = 500;
my $WANT = $KIDS * $PER;

# ---- the control: the same work, one process at a time ---------------------

{
    my $a = Shared::Arena->create(size => 8 * 1024 * 1024, regions => 4096);
    my $refused = 0;
    for my $i (0 .. $WANT - 1) {
        my @r = $a->region("n$i", size => 64);
        $refused++ unless @r;
    }
    my @names = $a->regions;
    is($refused, 0, 'serially, no carve was refused');
    is(scalar @names, $WANT, "serially, all $WANT names are in the registry");
}

# ---- the test: the same work, all at once ----------------------------------

{
    my $a = Shared::Arena->create(size => 8 * 1024 * 1024, regions => 4096);
    my @pid;
    for my $k (0 .. $KIDS - 1) {
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if (!$pid) {
            # A child that fails a carve reports how many, through its exit
            # status: a carve that was LOST reports nothing at all, which is
            # the whole point, so the name count below is what catches it.
            #
            # THE COUNT ALONE IS NOT A DIAGNOSIS. A smoker reported two of
            # these refused and the report could not say why, because an empty
            # list carries no reason and "full" and "busy" were the same code.
            # The first refusal in each child names its cause, which is the
            # difference between an arena with no room and a stripe whose
            # holder was not scheduled.
            my $fails = 0;
            for my $i (0 .. $PER - 1) {
                my @r = $a->region("k${k}_n$i", size => 64);
                next if @r;
                diag sprintf 'child %d: carve %d of %d refused, err %d '
                           . '(-12 full, -15 busy)', $k, $i, $PER, $a->_last_err
                    unless $fails;
                $fails++;
            }
            exit($fails > 254 ? 254 : $fails);
        }
        push @pid, $pid;
    }
    my $refused = 0;
    for my $pid (@pid) { waitpid($pid, 0); $refused += ($? >> 8); }

    my @names = $a->regions;
    is($refused, 0, "concurrently, no carve was refused");
    is(scalar @names, $WANT,
       "concurrently, all $WANT names survived - none was overwritten");

    # Two names sharing an offset would mean two callers were handed the same
    # bytes, which is worse than losing one of them.
    my (%off, %len);
    for my $n (@names) {
        my ($o, $l) = $a->region($n);
        $off{$o}++;
        $len{$l}++;
    }
    my @shared = grep { $off{$_} > 1 } keys %off;
    is(scalar @shared, 0, 'no two names were carved at the same offset');
    is_deeply([keys %len], [64], 'every entry kept the length it was carved with');
}

# ---- a refusal says which refusal it was -----------------------------------
#
# The diag above is only worth printing if the reason is real. A refused carve
# used to answer SA_E_FULL whether the registry was out of slots or a stripe
# was merely held, and an empty list said nothing at all - which is how the
# smoker report that prompted this could not tell the two apart. SA_E_BUSY is
# not reachable from here without starving the lock, so what is pinned is that
# a cause is recorded and that the causes are distinct.

{
    my $a = Shared::Arena->create(size => 1024 * 1024, regions => 8);
    ok(scalar($a->region('fits', size => 64)), 'a carve with room succeeds');
    is($a->_last_err, 0, '...and records no error');

    ok(!$a->region('absent'), 'a lookup of a name never carved misses');
    is($a->_last_err, -10, '...and says SA_E_NOENT, not that anything is full');

    ok(!$a->region('fits', size => 4096), 'a carve under a name of another size is refused');
    is($a->_last_err, -14, '...as SA_E_SHAPE');

    $a->region("fill$_", size => 64) for 1 .. 16;      # past the 8 slots
    ok(!$a->region('overflow', size => 64), 'a carve past the registry is refused');
    is($a->_last_err, -12, '...as SA_E_FULL, which is the one that means stop');
}

done_testing;
