#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Shared::Arena ();

# HOW MANY DISTINCT, IN A FEW KILOBYTES.
#
# The property this tenant exists for is the one a pool cannot get any other
# way: a key added by EVERY worker is counted ONCE. So the fork blocks below
# have four children add the same keys and assert the count is one set's worth,
# then have four children add disjoint keys and assert the union.
#
# The hash is deterministic, so every estimate here is the same on every run;
# the bounds are still the sketch's own error times a comfortable margin, not
# the exact number this build happens to produce, because a precise assertion
# of an estimate is a test of the hash, not of the sketch.

plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();

my $arena = Shared::Arena->create(size => 4 * 1024 * 1024);

# One fork call site (xt/win32-fork.t counts them against the SKIP guards),
# returning the pid so a caller can run several children at once.
sub spawn {
    my $code = shift;
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    unless ($pid) { $code->(); exit 0 }
    return $pid;
}

sub within {
    my ($got, $want, $frac, $name) = @_;
    my $lo = $want * (1 - $frac);
    my $hi = $want * (1 + $frac);
    ok($got >= $lo && $got <= $hi,
       sprintf('%s: %.0f is within %.1f%% of %d', $name, $got, $frac * 100, $want))
        or diag("wanted $lo .. $hi");
}

# ---- an estimate, its error, and repeats --------------------------------------

{
    my $h = $arena->hll('basic', precision => 14);
    is($h->precision, 14, 'the precision we asked for');
    my %s = $h->stats;
    is($s{registers}, 16384, '2^14 registers');
    cmp_ok($s{bytes}, '>', 16384, 'bytes is the registers plus a header');
    cmp_ok(abs($s{error} - 1.04 / sqrt(16384)), '<', 1e-9,
           'the quoted error is 1.04 / sqrt(registers)');
    is($h->count, 0, 'an empty sketch counts zero');

    $h->add("k$_") for 1 .. 10_000;
    # 0.8% one sigma at p = 14; 3% is well past three sigma.
    within($h->count, 10_000, 0.03, '10,000 distinct keys');

    my $before = $h->count;
    my $changed = 0;
    $changed += $h->add("k$_") ? 1 : 0 for 1 .. 10_000;
    is($changed, 0, 'adding every key again changes nothing');
    is($h->count, $before, '...and the count does not move by a hair');

    # A key can be new to the world and still not change the sketch.
    ok(!grep({ $h->add("k$_") } 1 .. 3), 'the return is about the sketch, not the key');

    $h->reset;
    is($h->count, 0, 'reset empties it');
    is({ $h->stats }->{filled}, 0, '...and no register is set');
}

# ---- small counts are close to exact -------------------------------------------

{
    my $h = $arena->hll('small', precision => 12);
    $h->add("s1");
    within($h->count, 1, 0.05, 'one key');
    $h->add("s$_") for 2 .. 50;
    within($h->count, 50, 0.05, 'fifty keys');
}

# ---- the precision is the sketch's --------------------------------------------

{
    $arena->hll('shape', precision => 10);
    my $wrong = eval { $arena->hll('shape', precision => 12) };
    ok(!$wrong, 'a different precision for an existing sketch is refused');
    like($@, qr/different type or size|shape/i, '...as a shape disagreement');
    my $inherit = $arena->hll('shape');
    is($inherit->precision, 10, 'naming no precision inherits the real one');

    my $bad = eval { $arena->hll('badp', precision => 3) };
    like($@, qr/precision must be/, 'a precision outside 4..18 is a croak');
}

# ---- merge is the union --------------------------------------------------------

{
    my $a = $arena->hll('ma', precision => 14);
    my $b = $arena->hll('mb', precision => 14);
    $a->add("u$_") for 1 .. 20_000;         # 1 .. 20000
    $b->add("u$_") for 10_001 .. 30_000;    # 10001 .. 30000: half overlaps
    within($a->count, 20_000, 0.03, 'a alone');
    within($b->count, 20_000, 0.03, 'b alone');
    my $b_before = $b->count;
    $a->merge($b);
    within($a->count, 30_000, 0.03, 'a merged with b is their union, not their sum');
    is($b->count, $b_before, 'and b is untouched');

    my $c = $arena->hll('mc', precision => 12);
    my $ok = eval { $a->merge($c); 1 };
    like($@, qr/cannot merge precision 12 into 14/, 'a precision mismatch croaks');
}

# ---- the same keys from every worker are counted ONCE ----------------------

SKIP: {
    skip 'fork is POSIX-only here', 1 if $^O eq 'MSWin32';

    my $h = $arena->hll('shared', precision => 14);
    my @pid = map {
        spawn(sub {
            my $mine = $arena->hll('shared');
            $mine->add("visitor-$_") for 1 .. 5000;   # every child, the SAME 5000
        });
    } 1 .. 4;
    waitpid($_, 0) for @pid;

    # Four workers each saw all 5000: the answer is 5000, not 20000.
    within($h->count, 5000, 0.03, 'four workers adding the same 5000 keys count 5000');
}

# ---- disjoint keys from every worker are the union -------------------------

SKIP: {
    skip 'fork is POSIX-only here', 1 if $^O eq 'MSWin32';

    my $h = $arena->hll('disjoint', precision => 14);
    my @pid = map {
        my $k = $_;
        spawn(sub {
            my $mine = $arena->hll('disjoint');
            $mine->add("w$k-$_") for 1 .. 5000;   # each child, its OWN 5000
        });
    } 1 .. 4;
    waitpid($_, 0) for @pid;

    within($h->count, 20_000, 0.03, 'four workers adding disjoint keys count their union');
}

# ---- racing adds lose nothing ---------------------------------------------
#
# Eight children add overlapping ranges at once. Every add is a max, so no
# matter how the writes interleave, the sketch ends up as if they had been
# applied one at a time - which a single process can reproduce exactly.

SKIP: {
    skip 'fork is POSIX-only here', 1 if $^O eq 'MSWin32';

    my $raced = $arena->hll('raced', precision => 12);
    my @pid = map {
        my $k = $_;
        spawn(sub {
            my $mine = $arena->hll('raced');
            # child k adds keys k*500 .. k*500 + 3000: heavy overlap
            $mine->add("r$_") for $k * 500 .. $k * 500 + 3000;
        });
    } 1 .. 8;
    waitpid($_, 0) for @pid;

    my $serial = $arena->hll('serial', precision => 12);
    for my $k (1 .. 8) { $serial->add("r$_") for $k * 500 .. $k * 500 + 3000 }

    is($raced->count, $serial->count,
       'eight racing writers produce exactly the serial result');
}

done_testing;
