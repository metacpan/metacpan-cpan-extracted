#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Shared::Arena ();

# A SET THAT ANSWERS "NO" EXACTLY, "YES" PROBABLY, AND CAN FORGET.
#
# One property is absolute, and it is the bloom filter's: a key that was added
# and not removed must check true, every time. Everything else - the rate, how
# full it gets, the counts - is statistical and asserted as a bound, or is
# bookkeeping.
#
# The absolute property is tested where it is actually at risk: a check running
# while keys move underneath it, and a process killed in the middle of moving
# them. A test that only adds and then checks, in one process, would pass
# against the textbook insert that loses a key every time it gives up.

plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();

my $arena = Shared::Arena->create(size => 32 * 1024 * 1024);

# Every child in this file is made here, so the file has one fork call site and
# each block that calls it sits inside a SKIP that is taken on MSWin32, where a
# "child" is a thread in this process and its exit would end the file. The
# child runs the block and leaves with POSIX::_exit, never exit, so it prints
# no TAP of its own; the block's value is its exit status.
sub spawn (&) {
    my ($code) = @_;
    require POSIX;
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    return $pid if $pid;
    my $rc = eval { $code->() };
    POSIX::_exit($@ ? 255 : ($rc // 0));
}

# ---- sizing ---------------------------------------------------------------
{
    my $f = $arena->cuckoo('sized', capacity => 10_000);
    isa_ok($f, 'Shared::Arena::Cuckoo');

    my %s = $f->stats;
    is($s{capacity}, 10_000, 'it records what it was sized for');
    cmp_ok($f->slots, '>=', 10_000, 'there is a slot for every key it was sized for');
    # Any bucket count, not only a power of two: rounding 10,000 keys up to a
    # power of two would have given it 16,384 slots.
    cmp_ok($f->slots, '<', 12_000, 'and not far over, because it is not rounded to a power of two');
    cmp_ok($s{bytes}, '<', 10_000 * 2.5, 'at about two bytes a key');
    is($s{count}, 0, 'and it holds nothing yet');
}

# ---- the hard guarantee: no false negatives -------------------------------
{
    my $f = $arena->cuckoo('exact-no', capacity => 5_000);

    my @keys = map { "key-$_-" . ('x' x ($_ % 17)) } 1 .. 5_000;
    my $refused = grep { !$f->add($_) } @keys;
    is($refused, 0, 'every one of 5,000 keys fits a filter sized for 5,000');

    my $missing = grep { !$f->check($_) } @keys;
    is($missing, 0, 'and every one checks true - a filter that says no about '
                  . 'something it stored is broken, not unlucky');
    is($f->count, 5_000, 'the count is exact');

    my $odd = $arena->cuckoo('odd-bytes', capacity => 100);
    my @odd = ("", "\0", "\0\0\0", "a\0b", join('', map { chr } 0 .. 255),
               "\xff" x 100, "unicode: \x{263a}");
    utf8::encode($odd[-1]);
    is(scalar(grep { !$odd->add($_) } @odd), 0,
       'keys of awkward bytes are stored, including an empty one');
    is(scalar(grep { !$odd->check($_) } @odd), 0, 'and found');
}

# ---- the soft one: false positives at the rate the width fixes -------------
{
    my $f = $arena->cuckoo('rate', capacity => 20_000);
    $f->add("present-$_") for 1 .. 20_000;

    # Keys that were never added. Any true answer is a false positive.
    my $tries = 50_000;
    my $false = grep { $f->check("absent-$_") } 1 .. $tries;
    my $rate  = $false / $tries;

    # About 0.011% at capacity: five or six in fifty thousand. A bound ten times
    # that, because a test that demanded the number would fail on an unlucky
    # hash and teach nobody anything.
    cmp_ok($rate, '<', 0.001,
           sprintf('the false-positive rate is near the 0.011%% sixteen-bit '
                 . 'fingerprints give (measured %.4f%% over %d misses)',
                   $rate * 100, $tries));

    my %s = $f->stats;
    cmp_ok($s{load}, '>', 0.85, 'at its capacity the filter is about 90% full');
    cmp_ok($s{load}, '<', 0.95, 'and not past it');
    cmp_ok($s{fp_rate}, '<', 0.0002, 'and the stats quote the rate for that load');
}

# ---- past capacity: refused, and nothing lost ------------------------------
#
# The textbook insert kicks a victim out to make room and carries it to its
# other bucket, and when the walk gives up the victim is simply gone. So the
# assertion that matters here is not the refusal but what survives it.
{
    my $f = $arena->cuckoo('overfull', capacity => 1_000);
    my (@stored, $first_refusal);
    for my $i (1 .. 2 * $f->slots) {
        if ($f->add("of$i")) { push @stored, "of$i" }
        elsif (!defined $first_refusal) { $first_refusal = $f->count / $f->slots }
    }

    ok(defined $first_refusal, 'a filter pushed past its slots refuses');
    cmp_ok($first_refusal // 0, '>', 0.9,
           sprintf('but not before it is past the 90%% its capacity fills '
                 . '(first refusal at %.1f%%)', 100 * ($first_refusal // 0)));
    is(scalar(grep { !$f->check($_) } @stored), 0,
       'and not one refusal cost a key already stored');

    my %s = $f->stats;
    cmp_ok($s{full}, '>', 0, 'refusals are counted');
    cmp_ok($s{kicks}, '>', 0, 'keys were moved to make room before it came to that');
    is($s{count}, scalar @stored, 'the count is exactly what was stored');
    cmp_ok($s{load}, '<=', 1, 'and never more than the slots');
}

# ---- it forgets --------------------------------------------------------------
{
    my $f = $arena->cuckoo('forget', capacity => 2_000);
    $f->add("r$_") for 1 .. 1_000;

    my @gone = grep { $_ % 2 } 1 .. 1_000;
    my @kept = grep { !($_ % 2) } 1 .. 1_000;

    is(scalar(grep { $f->remove("r$_") } @gone), 500,
       'every key that was added can be removed');
    is($f->count, 500, 'and the count follows');
    is(scalar(grep { !$f->check("r$_") } @kept), 0,
       'every key that stayed still checks true');

    # At a quarter full the rate is about 0.003%, so this is nearly always
    # zero; the bound only allows for the hash being unlucky.
    my $lingering = grep { $f->check("r$_") } @gone;
    cmp_ok($lingering, '<=', 2,
           "the removed keys check false, bar a coincidence ($lingering)");

    my $empty = $arena->cuckoo('empty', capacity => 100);
    is($empty->remove('never'), 0, 'removing from an empty filter finds nothing');
    is($empty->count, 0, 'and the count does not go below zero');
}

# ---- every add is a copy ---------------------------------------------------
{
    my $f = $arena->cuckoo('copies', capacity => 100);
    is(scalar(grep { $f->add('dup') } 1 .. 3), 3, 'a key added three times is stored three times');
    is($f->count, 3, 'as three copies');

    ok($f->remove('dup'), 'one copy is removed');
    ok($f->check('dup'), 'and the key is still there, because two copies are');
    ok($f->remove('dup') && $f->remove('dup'), 'the other two are removed');
    ok(!$f->check('dup'), 'and now it is gone');
    ok(!$f->remove('dup'), 'with nothing left to remove');

    # Every copy lives in the same two buckets of four.
    my $g = $arena->cuckoo('eight', capacity => 1_000);
    my $n = 0;
    $n++ while $n < 20 && $g->add('same');
    cmp_ok($n, '<=', 8, "one key can be added at most eight times ($n)");
    cmp_ok($n, '>=', 4, 'and at least as many times as one bucket holds');

    $g->add("other$_") for 1 .. 200;
    is(scalar(grep { !$g->check("other$_") } 1 .. 200), 0,
       'a key at its limit does not crowd anybody else out');
}

# ---- reset -----------------------------------------------------------------
{
    my $f = $arena->cuckoo('clearable', capacity => 1_000);
    $f->add("c$_") for 1 .. 100;
    ok($f->check('c50'), 'a key is there');

    $f->reset;
    is($f->count, 0, 'reset forgets the count');
    is($f->check('c50'), 0, 'and the key');
    ok($f->add('after') && $f->check('after'), 'and the filter works afterwards');
}

# ---- the shape is the filter's, not the caller's ----------------------------
{
    $arena->cuckoo('shape', capacity => 1_000);

    ok(!eval { $arena->cuckoo('shape', capacity => 100_000); 1 },
       'asking for a bigger filter under the same name is refused');
    like($@, qr/different type or size/, '...and says why');

    ok(!eval { $arena->cuckoo('shape', capacity => 10); 1 },
       'and so is asking for a smaller one');
    like($@, qr/different type or size/, '...for the same reason');

    ok(eval { $arena->cuckoo('shape', capacity => 1_000); 1 },
       'the same arguments attach');

    $arena->bloom('a-bloom', capacity => 100);
    ok(!eval { $arena->cuckoo('a-bloom', capacity => 100); 1 },
       'a name carved as another kind of tenant is refused');
}

# ---- across a fork ---------------------------------------------------------
#
# Skipped where fork is emulated with threads: a pseudo-process is a thread in
# THIS process, so a child that exits takes the file's plan with it.
SKIP: {
    skip 'fork is POSIX-only here', 3 if $^O eq 'MSWin32';
    require POSIX;

    # 18,000 into a filter sized for 20,000, so the last of them have to move
    # keys to make room while the others are still adding.
    my $f = $arena->cuckoo('forked', capacity => 20_000);
    my ($KIDS, $EACH) = (4, 4_500);

    my @pid;
    for my $kid (1 .. $KIDS) {
        push @pid, spawn {
            my $refused = grep { !$f->add("kid$kid-$_") } 1 .. $EACH;
            $refused > 250 ? 250 : $refused;
        };
    }
    my $refused = 0;
    for (@pid) { waitpid $_, 0; $refused += $? >> 8 }

    is($refused, 0, "$KIDS processes adding at once all got their keys in");

    my $missing = 0;
    for my $kid (1 .. $KIDS) {
        $missing += grep { !$f->check("kid$kid-$_") } 1 .. $EACH;
    }
    is($missing, 0, 'and every one of them is present in the parent');
    is($f->count, $KIDS * $EACH, 'and the count is exact, however they interleaved');
}

# ---- a check while keys move underneath it ---------------------------------
#
# The property that can actually fail. Moving a key copies it into its other
# bucket before deleting the old copy, so it is never in neither - but a check
# reads its two buckets one after the other, and a key that moves from the
# second to the first between those two reads is seen in neither. The filter
# closes that with a counter it compares on every miss.
#
# The window is a few instructions wide. Raced as it is, this test passed with
# the comparison deleted - no miss at all over 70,000 relocations - so it holds
# the window open: `_stall` makes every check that misses its first bucket
# sleep before reading its second, while writers churn a small, nearly full
# filter. With the comparison deleted it fails; with it, it must not.
SKIP: {
    skip 'fork is POSIX-only here', 4 if $^O eq 'MSWin32';
    require POSIX;

    my $f     = $arena->cuckoo('moving', capacity => 2_000);
    my $flags = $arena->map('moving-flags', slots => 16, slot_size => 64);
    my @anchor = map { "anchor-$_" } 1 .. 500;
    $f->add($_) or die "anchor refused" for @anchor;

    $f->_stall(300);

    my @readers;
    for my $r (1 .. 3) {
        pipe(my $rd, my $wr) or die "pipe: $!";
        my $pid = spawn {
            close $rd;
            my ($miss, $passes) = (0, 0);
            until ($flags->exists('done')) {
                $f->check($_) or $miss++ for @anchor;
                $passes++;
            }
            print {$wr} "$miss $passes\n";
            close $wr;
            0;
        };
        close $wr;
        push @readers, [$pid, $rd];
    }

    # Six writers, 250 keys each on top of the 500 anchors: the filter's whole
    # capacity. Then churn - take half out, put them back - which keeps it near
    # 90% and keeps keys moving. A writer only ever removes keys it stored.
    my @writers;
    for my $w (1 .. 6) {
        push @writers, spawn {
            my @mine = grep { $f->add($_) } map { "w$w-$_" } 1 .. 250;
            for (1 .. 300) {
                my @out = grep { $f->remove($_) } @mine[grep { !($_ % 2) } 0 .. $#mine];
                my %out = map { $_ => 1 } @out;
                @mine = ((grep { !$out{$_} } @mine), (grep { $f->add($_) } @out));
            }
            0;
        };
    }
    waitpid $_, 0 for @writers;
    $flags->store('done', 1);

    my ($miss, $passes) = (0, 0);
    for (@readers) {
        my ($pid, $rd) = @$_;
        my $line = <$rd>;
        close $rd;
        waitpid $pid, 0;
        my ($m, $p) = split ' ', ($line // '0 0');
        $miss   += $m;
        $passes += $p;
    }
    $f->_stall(0);

    my %s = $f->stats;
    cmp_ok($s{moves}, '>', 1_000, "keys really did move while the checks ran ($s{moves})");
    cmp_ok($passes, '>', 0, "and the readers were checking ($passes passes)");
    is($miss, 0, 'NOT ONE check missed an anchor, across every one of those moves');
    is(scalar(grep { !$f->check($_) } @anchor), 0, 'and every anchor is still there');
}

# ---- a process that died holding the right to move keys ---------------------
#
# One lock per filter serialises moving keys, so a process killed holding it
# would otherwise refuse every later add that needs room made, for the life of
# the arena. The lock names its holder's pid, and a waiter that finds the holder
# gone takes it over. `_owner` plants a holder, rather than this test trying to
# kill one at exactly the wrong instant.
SKIP: {
    skip 'needs fork and kill', 6 if $^O eq 'MSWin32';
    require POSIX;

    my $f = $arena->cuckoo('orphaned', capacity => 10_000);
    my @pre;
    for my $i (1 .. 20_000) {
        last if $f->count >= 0.92 * $f->slots;
        push @pre, "pre$i" if $f->add("pre$i");
    }

    # A live holder: a child that does nothing but exist.
    my $pid = spawn { sleep 30; 0 };

    $f->_owner($pid);
    my $refused = grep { !$f->add("held-$_") } 1 .. 40;
    cmp_ok($refused, '>', 0, 'while a live process holds the lock, an add that '
                           . 'needs keys moved is refused rather than waiting for ever');
    is($f->_owner, $pid, 'and the live holder keeps it');

    kill 'KILL', $pid;
    waitpid $pid, 0;

    my $stored = grep { $f->add("after-$_") } 1 .. 40;
    my %s = $f->stats;
    cmp_ok($s{recovered}, '>=', 1, 'once the holder has died, the next add that '
                                 . 'needs the lock takes it over');
    is($f->_owner, 0, 'and lets it go afterwards');
    is($stored, 40, 'so every add that needed keys moved works again');
    is(scalar(grep { !$f->check($_) } @pre), 0, 'with nothing stored before lost');
}

# ---- a worker killed mid-add ------------------------------------------------
#
# Killed anywhere - between the copy and the delete of a move, holding the lock,
# half way through a plan - a writer can leave a key stored twice, and never a
# key stored nowhere.
SKIP: {
    skip 'needs fork and kill', 2 if $^O eq 'MSWin32';
    require POSIX;

    my $f = $arena->cuckoo('crash', capacity => 5_000);
    my @keep = map { "keep-$_" } 1 .. 1_000;
    $f->add($_) or die "refused" for @keep;

    my @pid;
    for my $kid (1 .. 3) {
        push @pid, spawn {
            # About 1,400 keys each, on top of the 1,000: past 90%, where most
            # adds move something. Oldest out first, and only keys it stored.
            my ($n, @mine) = (0);
            while (1) {
                my $k = "k$kid-" . $n++;
                push @mine, $k if $f->add($k);
                $f->remove(shift @mine) if @mine > 1_400;
            }
        };
    }
    select undef, undef, undef, 0.5;
    kill 'KILL', $_ for @pid;
    waitpid $_, 0 for @pid;

    is(scalar(grep { !$f->check($_) } @keep), 0,
       'workers killed mid-add left every key they never touched in place');
    cmp_ok(scalar(grep { $f->add("after$_") } 1 .. 20), '>', 0,
           'and the filter still stores after a hard kill');
}

done_testing;
