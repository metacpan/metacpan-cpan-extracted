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
            my $fails = 0;
            for my $i (0 .. $PER - 1) {
                my @r = $a->region("k${k}_n$i", size => 64);
                $fails++ unless @r;
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

done_testing;
