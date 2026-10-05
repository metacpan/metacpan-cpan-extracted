#!/usr/bin/env perl
# What the numeric functions do with an argument that is not a number, and
# with a NaN.
#
# Three changes in 0.312, none of which can fail loudly on their own -- each
# used to return a plausible number instead of an answer:
#
# 1. A string that is not a number went through SvNV() and became 0.  undef
#    had always been an error; 'abc' was not, and nothing warned, because
#    SvNV() on a PV only warns under `use warnings 'numeric'` in the caller's
#    scope, which an XSUB does not run in.  min(1, 2, 'abc') returned 0 -- a
#    value that is not among its arguments and is not the smallest of them --
#    and mean(1, 2, 'abc') returned 1.  These now croak, via
#    looks_like_number(), which is what the rest of the file already validates
#    with; an object that overloads its numeric conversion still counts as a
#    number, and a reference that does not is now refused as well (SvNV() on
#    one returns its address).
#
# 2. median() and quantile() placed a NaN by comparison, and no comparison
#    sort can: every comparison against a NaN is false, so which value ended
#    up in the middle depended on where in the array the NaN sat.
#    median(1..50 with one NaN) returned 25.5 while median([1,2,NaN,4])
#    returned NaN, and quantile() of the same 50 answered 13.25 for the 25%
#    and NaN for the 75%.  Both now propagate: one NaN in, NaN out, which is
#    what sum(), mean(), var(), sd(), min() and max() have always done here
#    (t/minmax.nan.R.t) and what R does -- R's median(c(1,2,NaN)) is NA and
#    its mean(c(1,2,NaN)) is NaN.  R's quantile() refuses such input outright
#    ("missing values and NaN's not allowed if 'na.rm' is FALSE"); propagating
#    keeps the 50% quantile equal to median(), which is the stronger
#    invariant here.
#
# 3. bw_nrd0() and bw_nrd() accepted a non-finite value and returned a number
#    -- 7.5250570111922 for 1..50 with two NaNs in it, computed from a
#    variance and an interquartile range that are both NaN via a min() that a
#    NaN silently loses -- where bw_ucv(), bw_bcv() and bw_sj() rejected it a
#    layer down.  All five now refuse it in the shared reader, which is also
#    what keeps a NaN out of the qsort() there: cmp_nv3() cannot order one, and
#    an inconsistent comparator makes qsort() undefined behaviour rather than
#    merely inaccurate.  R errors on all five ("missing values and NaN's not
#    allowed if 'na.rm' is FALSE").
#
# 4. A ragged HoA frame -- columns of different lengths -- was fitted on
#    whichever column hv_iternext() reached first, so how many rows lm(),
#    glm() and prcomp() used moved with hash order from run to run.  All three
#    now croak, as csort() already did.  This is stricter than R, on purpose:
#    data.frame() recycles a short column when its length divides the longest,
#    so data.frame(y = 1:6, x = 1:3) quietly fits on x repeated twice, and
#    only data.frame(y = 1:6, x = 1:4) is an error there.
#
# Provenance: R 4.6.1 (2026-06-24) for every R behaviour quoted above.  No
# value here needs R to be present.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib 'blib/lib', 'blib/arch';
use Stats::LikeR qw(mean sum min max median var sd skew kurtosis quantile
                    scale hist lm glm prcomp bw_nrd0 bw_nrd bw_ucv bw_bcv bw_sj);

my $NAN = 9**9**9 - 9**9**9;
my $INF = 9**9**9;

# --- 1. non-numeric arguments ----------------------------------------------
{
	my @fns = qw(mean sum min max median var sd);
	for my $fn (@fns) {
		no strict 'refs';
		my $f = \&{"Stats::LikeR::$fn"};
		my $err = do { local $@; eval { $f->(1, 2, 'abc') }; $@ };
		like($err, qr/^\Q$fn\E: non-numeric value at argument index 2/,
			"$fn(1, 2, 'abc') croaks, naming the argument");
		$err = do { local $@; eval { $f->([1, 2, 'abc']) }; $@ };
		like($err, qr/^\Q$fn\E: non-numeric value at array ref index 2/,
			"$fn([1, 2, 'abc']) croaks, naming the cell");
		$err = do { local $@; eval { $f->([1, 2, undef]) }; $@ };
		like($err, qr/^\Q$fn\E: undefined value/,
			"$fn: undef is still refused, and still says 'undefined'");
	}
	for my $fn (qw(skew kurtosis)) {
		no strict 'refs';
		my $f = \&{"Stats::LikeR::$fn"};
		my $err = do { local $@; eval { $f->([1, 2, 3, 'abc', 5]) }; $@ };
		like($err, qr/^\Q$fn\E: non-numeric value at array ref index 3/,
			"$fn croaks on a non-numeric cell");
	}
	my $err = do { local $@; eval { quantile([1, 2, 'abc']) }; $@ };
	like($err, qr/^quantile: non-numeric value at index 2/,
		'quantile croaks on a non-numeric cell');
	$err = do { local $@; eval { hist([1, 2, 'abc']) }; $@ };
	like($err, qr/^hist: non-numeric value at index 2/,
		'hist croaks on a non-numeric cell');
}

# Numeric strings are numbers, and so is an object that overloads 0+.
{
	package t::Overloaded;
	use overload '0+' => sub { $_[0]{v} }, fallback => 1;
	sub new { my ($c, $v) = @_; return bless { v => $v }, $c }
}
{
	is(mean(['1', '2', '3']), 2, 'a column of numeric strings is numeric');
	is(mean([' 4 ', "5\n", '+6']), 5,
		'and so are the spellings perl itself accepts');
	is(mean([1e3, '1e3']), 1000, 'exponent notation, as a number and as a string');
	my @o = map { t::Overloaded->new($_) } 1, 2, 6;
	is(mean(\@o), 3, 'an object overloading 0+ counts as its number');
	is(min(\@o),  1, '... in min() too');
	my $err = do { local $@; eval { mean([1, 2, []]) }; $@ };
	like($err, qr/^mean: non-numeric value at array ref index 2/,
		'a plain reference is refused rather than folded in as its address');
}

# --- 2. NaN propagation -----------------------------------------------------
{
	my @with_nan = (1 .. 50);
	$with_nan[7] = $NAN;
	ok(median(\@with_nan) != median(\@with_nan),
		'median of 1..50 with one NaN is NaN (it was 25.5)');
	ok(median([5, 1, $NAN]) != median([5, 1, $NAN]),
		'median([5, 1, NaN]) is NaN (it was 5)');
	ok(median([1, 2, $NAN, 4]) != median([1, 2, $NAN, 4]),
		'median([1, 2, NaN, 4]) is NaN, as before');
	is(median([1 .. 50]), 25.5, 'and a clean column is unaffected');

	my $q = quantile(\@with_nan);
	for my $k (sort keys %$q) {
		ok($q->{$k} != $q->{$k}, "quantile: $k is NaN when the sample holds one");
	}
	my $q2 = quantile([1 .. 50]);
	is($q2->{'50%'}, 25.5, 'a clean sample still gives numbers');
	is($q2->{'50%'}, median([1 .. 50]), 'and the 50% quantile is the median');

	# undef is dropped, as the documentation says, and is not a NaN
	my $q3 = quantile([1, 2, undef, 4]);
	is($q3->{'50%'}, 2, 'undef is still dropped rather than propagated');
}

# --- 3. bandwidth selectors -------------------------------------------------
{
	for my $fn (qw(bw_nrd0 bw_nrd bw_ucv bw_bcv bw_sj)) {
		no strict 'refs';
		my $f = \&{"Stats::LikeR::$fn"};
		for my $bad ([$NAN, 'NaN'], [$INF, 'Inf'], [-$INF, '-Inf']) {
			my ($v, $name) = @$bad;
			my @x = (1 .. 50);
			$x[7] = $v;
			my $err = do { local $@; eval { $f->(\@x) }; $@ };
			like($err, qr/^\Q$fn\E: non-finite x in bandwidth calculation/,
				"$fn refuses a $name");
		}
		ok($f->([1 .. 50]) > 0, "$fn still works on clean data");
	}
}

# --- 4. ragged frames -------------------------------------------------------
{
	my %ragged = (y => [1 .. 6], x => [1, 2, 3]);
	my $err = do { local $@; eval { lm(formula => 'y ~ x', data => \%ragged) }; $@ };
	like($err, qr/^lm: HoA columns have unequal lengths/,
		'lm refuses a ragged HoA frame');
	$err = do { local $@;
		eval { glm(formula => 'y ~ x', data => \%ragged, family => 'gaussian') }; $@ };
	like($err, qr/^glm: HoA columns have unequal lengths/,
		'glm refuses it too');
	$err = do { local $@; eval { prcomp(\%ragged) }; $@ };
	like($err, qr/^prcomp: HoA columns have unequal lengths/,
		'and prcomp');
	$err = do { local $@; eval { prcomp([[1, 2], [3], [5, 6]]) }; $@ };
	like($err, qr/^prcomp: AoA rows have unequal lengths/,
		'prcomp refuses a ragged AoA too, naming the row');

	# the rectangular cases still fit
	my %ok = (y => [1, 2, 3, 4, 5, 7], x => [1, 2, 3, 4, 5, 6]);
	my $fit = lm(formula => 'y ~ x', data => \%ok);
	is($fit->{'df_residual'}, 4, 'a rectangular frame fits on all its rows');
	my $p = prcomp({ a => [1, 2, 3, 4], b => [2, 1, 4, 3] });
	is(scalar @{ $p->{sdev} }, 2, 'and prcomp decomposes a rectangular one');
}

done_testing();
