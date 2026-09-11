#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Shared::Arena ();

# A SET THAT ANSWERS "NO" EXACTLY AND "YES" PROBABLY.
#
# The two properties worth testing are not symmetrical, and only one of them is
# absolute:
#
#   * NO FALSE NEGATIVES, EVER. A key that was added must always check true.
#     This is a hard guarantee and a single counter-example is a bug.
#   * FALSE POSITIVES AT ABOUT THE RATE ASKED FOR. This is statistical, so it
#     is asserted as a generous bound rather than a number: a test that
#     demanded 1.00% would fail on an unlucky seed and teach nobody anything.
#
# Nothing here asserts a particular bit pattern or a hash value. Those would be
# a copy of the implementation rather than a check on it, and would have to be
# rewritten the day the mixing changes, which is exactly when a test should be
# holding still.

plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();

my $arena = Shared::Arena->create(size => 8 * 1024 * 1024);

# ---- sizing ---------------------------------------------------------------
{
    my $b = $arena->bloom('sized', capacity => 10_000, fp_rate => 0.01);
    isa_ok($b, 'Shared::Arena::Bloom');

    # About 9.6 bits per item at one percent, and about 7 hashes. Bounds rather
    # than equalities: the arithmetic is standard but the rounding is ours.
    cmp_ok($b->bits, '>', 10_000 * 8, 'a 1% filter for 10k items takes more than 8 bits each');
    cmp_ok($b->bits, '<', 10_000 * 12, 'and fewer than 12');
    cmp_ok($b->hashes, '>=', 5, 'with a sensible number of hashes');
    cmp_ok($b->hashes, '<=', 9, 'neither too few nor absurdly many');

    # A tighter rate must cost more bits. That relationship is the whole point
    # of asking for a rate rather than a size.
    my $tight = $arena->bloom('tight', capacity => 10_000, fp_rate => 0.0001);
    cmp_ok($tight->bits, '>', $b->bits,
           'a tighter false-positive rate buys more bits');
    cmp_ok($tight->hashes, '>', $b->hashes, 'and more hashes');

    # A caller who has done the arithmetic can say so directly.
    my $exact = $arena->bloom('exact', bits => 4096, hashes => 3);
    is($exact->bits, 4096, 'bits can be given directly');
    is($exact->hashes, 3, 'and so can the hash count');
}

# ---- the hard guarantee: no false negatives -------------------------------
{
    my $b = $arena->bloom('exact-no', capacity => 5_000, fp_rate => 0.01);

    my @keys = map { "key-$_-" . ('x' x ($_ % 17)) } 1 .. 5_000;
    $b->add($_) for @keys;

    my $missing = grep { !$b->check($_) } @keys;
    is($missing, 0, 'every one of 5,000 added keys checks true - a filter that '
                  . 'says no about something it was given is broken, not '
                  . 'unlucky');

    # Including keys with awkward bytes.
    my @odd = ("", "\0", "\0\0\0", "a\0b", join('', map { chr } 0 .. 255),
               "\xff" x 100, "unicode: \x{263a}");
    utf8::encode($odd[-1]);
    $b->add($_) for @odd;
    is(scalar(grep { !$b->check($_) } @odd), 0,
       'and so does every key of awkward bytes, including an empty one');
}

# ---- the soft one: false positives near the rate asked for ----------------
{
    my $b = $arena->bloom('rate', capacity => 20_000, fp_rate => 0.01);

    $b->add("present-$_") for 1 .. 20_000;

    # Keys that were definitely never added. Any true answer here is a false
    # positive by definition.
    my $tries = 20_000;
    my $false = grep { $b->check("absent-$_") } 1 .. $tries;
    my $rate  = $false / $tries;

    cmp_ok($rate, '<', 0.05,
           sprintf('the false-positive rate is near the 1%% asked for '
                 . '(measured %.2f%% over %d misses)', $rate * 100, $tries));

    # And the filter is not simply saying yes to everything, which would also
    # pass a "no false negatives" test.
    cmp_ok($rate, '<', 0.5, 'and it is not answering true indiscriminately');
    my %s = $b->stats;
    cmp_ok($s{fill}, '>', 0.1, 'the filter has real bits set');
    cmp_ok($s{fill}, '<', 0.9, 'and is not saturated at its rated capacity');
}

# ---- what the stats say ---------------------------------------------------
{
    my $b = $arena->bloom('counted', capacity => 1_000, fp_rate => 0.01);

    my %empty = $b->stats;
    is($empty{set}, 0, 'a new filter has no bits set');
    is($empty{estimated}, 0, 'and estimates nothing in it');
    is($empty{added}, 0, 'and nothing added');

    is($b->add('first'), 0, 'adding a new key reports it was new');
    is($b->add('first'), 1, 'adding it again reports it was already there');

    $b->add("k$_") for 1 .. 500;
    my %s = $b->stats;
    cmp_ok($s{set}, '>', 0, 'bits are set');
    cmp_ok($s{added}, '>=', 500, 'and the adds were counted');

    # The estimate is arithmetic on the bits, so it should land near the truth
    # while the filter is well within its rating.
    cmp_ok($s{estimated}, '>', 350, 'the estimated count is in the region of '
                                  . 'the 501 distinct keys added');
    cmp_ok($s{estimated}, '<', 700, 'and is not wildly over');
}

# ---- reset forgets everything ---------------------------------------------
{
    my $b = $arena->bloom('forgetful', capacity => 1_000, fp_rate => 0.01);
    $b->add("k$_") for 1 .. 100;
    ok($b->check('k50'), 'a key is there');

    $b->reset;
    my %s = $b->stats;
    is($s{set}, 0, 'reset clears every bit');
    is($s{added}, 0, 'and the counters');
    is($b->check('k50'), 0, 'and the key is gone');

    # A filter that has been reset is usable again rather than merely empty.
    $b->add('after');
    ok($b->check('after'), 'and it works afterwards');
}

# ---- across a fork --------------------------------------------------------
SKIP: {
    skip 'fork is POSIX-only here', 3 if $^O eq 'MSWin32';
    require POSIX;

    my $b = $arena->bloom('forked', capacity => 20_000, fp_rate => 0.01);

    # Four children each add a disjoint range. Setting a bit is one atomic OR
    # and nothing takes a lock, so nothing should be lost however they overlap.
    my $KIDS = 4;
    my $EACH = 2_000;
    my @pids;
    for my $kid (1 .. $KIDS) {
        my $pid = fork();
        die "fork: $!" unless defined $pid;
        if (!$pid) {
            $b->add("kid$kid-$_") for 1 .. $EACH;
            POSIX::_exit(0);
        }
        push @pids, $pid;
    }
    waitpid $_, 0 for @pids;

    my $missing = 0;
    for my $kid (1 .. $KIDS) {
        $missing += grep { !$b->check("kid$kid-$_") } 1 .. $EACH;
    }
    is($missing, 0,
       "every one of the @{[ $KIDS * $EACH ]} keys added by $KIDS processes is "
     . 'present - a bit set by one process is set for all of them');

    my %s = $b->stats;
    cmp_ok($s{estimated}, '>', $KIDS * $EACH * 0.7,
           'and the estimate reflects roughly what went in');

    # The parent never added anything itself, and still sees all of it.
    ok($b->check("kid1-1"), 'the parent sees what a child added');
}

done_testing;
