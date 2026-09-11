#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Shared::Arena ();

# A DISTRIBUTION EVERY PROCESS ADDS TO AT ONCE.
#
# The claim to check is not that a quantile is right - a histogram is inexact
# on purpose - it is that the inexactness is BOUNDED and in a known direction:
#
#   * a value comes back within the error bound the histogram reports
#   * a quantile is reported as the TOP of its bucket, so it never claims the
#     service was faster than it was
#   * small values are exact, because at that size a bucket is one unit wide
#
# So every assertion below is written against the bound the histogram itself
# reports, not against numbers that would have to be rewritten the day the
# bucketing changes.

plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();

my $arena = Shared::Arena->create(size => 8 * 1024 * 1024);

# ---- the error bound is what it says it is --------------------------------
{
    my $h = $arena->histogram('bounded', max => 1_000_000, sigbits => 4);
    my $err = $h->error;
    is($err, 1/16, 'four significant bits is a sixteenth');

    # A value recorded once must come back within the bound, at every scale.
    # This is the property the whole log-linear scheme exists to provide: the
    # error is relative, so it is the same at 10 and at 900,000.
    for my $v (1, 2, 7, 15, 16, 17, 100, 999, 1_000, 12_345, 999_999) {
        my $one = $arena->histogram("v$v", max => 1_000_000, sigbits => 4);
        $one->record($v);
        my $got = $one->quantile(0.5);
        cmp_ok($got, '>=', $v, "$v: the answer is never below the value");
        cmp_ok($got, '<=', $v + $v * $err + 1,
               "$v: and never further above it than the error bound allows");
    }
}

# ---- small values are exact ------------------------------------------------
{
    my $h = $arena->histogram('exact', max => 100_000, sigbits => 5);
    # Below 2^sigbits a bucket is one unit wide, so these are not estimates.
    for my $v (0 .. 31) {
        my $one = $arena->histogram("e$v", max => 100_000, sigbits => 5);
        $one->record($v);
        is($one->quantile(0.5), $v, "$v is recorded exactly");
    }
}

# ---- more significant bits, tighter answers --------------------------------
{
    my $coarse = $arena->histogram('coarse', max => 1_000_000, sigbits => 2);
    my $fine   = $arena->histogram('fine',   max => 1_000_000, sigbits => 7);

    cmp_ok($coarse->error, '>', $fine->error,
           'fewer significant bits means a looser bound');

    my %c = $coarse->stats;
    my %f = $fine->stats;
    cmp_ok($f{buckets}, '>', $c{buckets},
           'and the tighter one costs more buckets, which is the trade');

    $_->record(10_000) for $coarse, $fine;
    my $cerr = abs($coarse->quantile(0.5) - 10_000) / 10_000;
    my $ferr = abs($fine->quantile(0.5) - 10_000) / 10_000;
    cmp_ok($cerr, '<=', $coarse->error, 'each stays inside its own bound');
    cmp_ok($ferr, '<=', $fine->error, 'including the tight one');
    cmp_ok($ferr, '<=', $cerr, 'and the tight one is at least as close');
}

# ---- quantiles over a known distribution -----------------------------------
{
    my $h = $arena->histogram('quantiles', max => 100_000, sigbits => 6);
    my $err = $h->error;

    # One to a thousand, each once: the p50 is 500, the p90 is 900, the p99
    # is 990. Any bucketing that gets these wrong is wrong.
    $h->record($_) for 1 .. 1_000;

    is($h->count, 1_000, 'every value was recorded');

    for my $pair ([0.5, 500], [0.9, 900], [0.99, 990]) {
        my ($q, $want) = @$pair;
        my $got = $h->quantile($q);
        cmp_ok($got, '>=', $want - 1,
               "p@{[ $q * 100 ]} is not below $want");
        cmp_ok($got, '<=', $want + $want * $err + 1,
               "p@{[ $q * 100 ]} is within the bound of $want (got $got)");
    }

    my %s = $h->stats;
    is($s{min}, 1, 'the minimum is exact, not bucketed');
    is($s{max}, 1_000, 'and so is the maximum');
    is($s{sum}, 500_500, 'the sum is exact too, being an addition and not a bucket');
    cmp_ok(abs($s{mean} - 500.5), '<', 0.001, 'so the mean is exact');
}

# ---- a value past the ceiling is counted apart, not clamped ---------------
{
    my $h = $arena->histogram('ceiling', max => 1_000, sigbits => 4);

    $h->record(500) for 1 .. 10;
    $h->record(1_000_000) for 1 .. 5;

    my %s = $h->stats;
    is($s{count}, 10, 'a value above the ceiling is not counted as recorded');
    is($s{over}, 5, 'it is counted as an overflow');
    is($s{max}, 500, 'and does not move the maximum');

    # The point of counting them apart: if they had been clamped into the top
    # bucket, this quantile would read plausibly and be nonsense.
    cmp_ok($h->quantile(0.99), '<=', 1_000,
           'so the quantiles still describe what actually fitted');
}

# ---- reset -----------------------------------------------------------------
{
    my $h = $arena->histogram('forget', max => 10_000, sigbits => 4);
    $h->record($_) for 1 .. 100;
    cmp_ok($h->count, '>', 0, 'it has values');

    $h->reset;
    my %s = $h->stats;
    is($s{count}, 0, 'reset clears the count');
    is($s{sum}, 0, 'and the sum');
    is($s{max}, 0, 'and the maximum');
    is($s{min}, 0, 'and the minimum reads as zero when empty');
    is_deeply([$h->buckets], [], 'and every bucket is empty');

    $h->record(42);
    is($h->count, 1, 'and it records again afterwards');
}

# ---- the buckets themselves ------------------------------------------------
{
    my $h = $arena->histogram('shape', max => 10_000, sigbits => 4);
    $h->record(100) for 1 .. 7;
    $h->record(5_000) for 1 .. 3;

    my @b = $h->buckets;
    is(scalar @b, 2, 'two values used two buckets');
    is($b[0][2], 7, 'the first holds seven');
    is($b[1][2], 3, 'the second holds three');
    cmp_ok($b[0][0], '<=', 100, 'and the first bucket contains 100');
    cmp_ok($b[0][1], '>=', 100, 'between its low and its high');
    cmp_ok($b[1][0], '<=', 5_000, 'and the second contains 5,000');
    cmp_ok($b[1][1], '>=', 5_000, 'likewise');
    cmp_ok($b[0][1], '<', $b[1][0], 'and the buckets do not overlap');
}

# ---- across a fork ---------------------------------------------------------
SKIP: {
    skip 'fork is POSIX-only here', 4 if $^O eq 'MSWin32';
    require POSIX;

    my $h = $arena->histogram('forked', max => 100_000, sigbits => 5);

    my $KIDS = 4;
    my $EACH = 1_000;
    my @pids;
    for my $kid (1 .. $KIDS) {
        my $pid = fork();
        die "fork: $!" unless defined $pid;
        if (!$pid) {
            # Each child records the same range, so a lost increment shows up
            # in the count rather than hiding in a quantile.
            $h->record($_) for 1 .. $EACH;
            POSIX::_exit(0);
        }
        push @pids, $pid;
    }
    waitpid $_, 0 for @pids;

    my %s = $h->stats;
    is($s{count}, $KIDS * $EACH,
       "every one of the @{[ $KIDS * $EACH ]} values from $KIDS processes "
     . 'landed - recording is one atomic add, so nothing needs merging');
    is($s{sum}, $KIDS * ($EACH * ($EACH + 1) / 2),
       'and the sum is exactly right, which a lost add would not be');
    is($s{min}, 1, 'with the minimum across all of them');
    is($s{max}, $EACH, 'and the maximum');
}

done_testing;
