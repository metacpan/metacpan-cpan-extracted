#!/usr/bin/env perl
# median(), against R's and NumPy's own cases.
#
# Provenance:
#   R      R 4.6.1 src/library/stats/man/median.Rd, \examples: median(1:4) is
#          2.5, median(c(1:3, 100, 1000)) is 3.
#          tests/reg-tests-2.R, "quantile extremes, MM 13 Apr 2000 and
#          PR#1852": median(c(-Inf, -Inf, Inf, Inf)) is NaN ("1.5.1 had -Inf
#          not NaN in several places").
#          tests/reg-tests-1a.R, "return value of median": median(numeric(0))
#          is NA_real_.
#          Also run in R 4.6.2: median(c(1e308, 1e308)) 1e308, median(c(-Inf,
#          1, 2)) 1, median(c(-Inf, Inf)) NaN, median(c(1, NA, 3)) NA,
#          median(c(-7, 3)) -2.
#   NumPy  2.4.6, numpy/lib/tests/test_function_base.py, class TestMedian:
#          test_basic (arange(2), arange(6).reshape(2, 3) overall and per axis,
#          the four-value and three-value float arrays), test_axis_keyword (a3,
#          the input is left unchanged and the medians 3, 4 and 3.5),
#          test_array_like, test_nan_behavior (a NaN anywhere gives NaN).
#   t/median.dnorm.summary.R.R (committed beside this file) printed the R
#   values; re-run it with
#       Rscript t/median.dnorm.summary.R.R
#   This test never runs R or Python.
#
# Tolerance: none; every median here is a middle value or the exact mean of two
# dyadic or short decimal values, compared with ==, except the NumPy float case
# (0.0463301 + 0.0606775) / 2, which is compared to 1e-15 relative (about 4500
# double epsilons, headroom for wider NVs).
#
# Deliberate differences, kept so that changing one is a decision:
#   - R's median(numeric(0)) is NA; median([]) croaks (it "needs >= 1
#     element").  The README says only that undefined values die.
#   - median() has no na.rm; an undef croaks (README) where R returns NA, and a
#     NaN gives NaN as R's NA does.
#   - NumPy's axis argument has no counterpart; each axis case is the median of
#     that row or column.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # throws_ok / lives_and
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

my $INF = 9**9**9;
sub isnan_ { my ($v, $name) = @_; ok(defined $v && $v != $v, $name) or diag('got ' . ($v // 'undef')) }

#--------
# R
#--------
is(median(1 .. 4), 2.5, 'R median.Rd: median(1:4)');
is(median(1, 2, 3, 100, 1000), 3, 'R median.Rd: median(c(1:3, 100, 1000))');
is(median([1, 2, 3, 100, 1000]), 3, 'R median.Rd: arrayref form');
isnan_(median(-$INF, -$INF, $INF, $INF), 'R reg-tests-2: median(c(-Inf, -Inf, Inf, Inf)) is NaN');
isnan_(median(-$INF, $INF), 'R: median(c(-Inf, Inf)) is NaN');
is(median(-$INF, 1, 2), 1, 'R: median(c(-Inf, 1, 2)) is 1');
is(median(1e308, 1e308), 1e308, 'R: median(c(1e308, 1e308)) does not overflow (README)');
is(median(-1e308, -1e308), -1e308, 'median(c(-1e308, -1e308)) does not overflow');
is(median(1e308, -1e308), 0, 'median(c(1e308, -1e308)) is 0');
is(median(-7, 3), -2, 'R: median(c(-7, 3)) is -2');
is(median(5, 5, 5, 5), 5, 'median of identical values');
isnan_(median(1, 'NaN', 3), 'R: median(c(1, NA, 3)) is NA; here NaN');
throws_ok { median([]) } qr/median needs >= 1 element/,
	'R reg-tests-1a: median(numeric(0)) is NA in R; median([]) croaks (see header)';
throws_ok { median(1, undef, 3) } qr/undefined value/,
	'R: median(c(1, NA, 3)) is NA; an undef croaks (README)';

#--------
# NumPy, TestMedian
#--------
is(median(1), 1, 'test_basic: median(array(1)) is 1');
is(median(0, 1), 0.5, 'test_basic: median(arange(2))');
is(median([0 .. 5]), 2.5, 'test_basic: median(arange(6).reshape(2, 3)), axis None');
is(median(0, 3), 1.5, 'test_basic: axis=0 column 0 of arange(6).reshape(2, 3)');
is(median(1, 4), 2.5, 'test_basic: axis=0 column 1');
is(median(2, 5), 3.5, 'test_basic: axis=0 column 2');
is(median(0, 1, 2), 1, 'test_basic: axis=1 row 0');
is(median(3, 4, 5), 4, 'test_basic: axis=1 row 1');
{
	my @a = (0.0444502, 0.0463301, 0.141249, 0.0606775);
	my $m = median(\@a);
	ok(abs($m - 0.053503800000000004) <= 1e-15 * 0.0535038, 'test_basic: four floats, mean of the middle two')
		or diag("got $m");
	is(median(0.0463301, 0.0444502, 0.141249), 0.0463301, 'test_basic: three floats, first is the median');
	is(median(0.0444502, 0.141249, 0.0463301), 0.0463301, 'test_basic: three floats, last is the median');
	is_deeply(\@a, [0.0444502, 0.0463301, 0.141249, 0.0606775], 'median leaves its input unsorted and unchanged');
}
{
	my @a3 = (2, 3, 0, 1, 6, 7, 4, 5); # test_axis_keyword's a3, row-major
	my @orig = @a3;
	is(median(\@a3), 3.5, 'test_axis_keyword: median(a3) is 3.5');
	is(median(2, 0, 6, 4), 3, 'test_axis_keyword: a3 axis=0, column 0');
	is(median(3, 1, 7, 5), 4, 'test_axis_keyword: a3 axis=0, column 1');
	is_deeply(\@a3, \@orig, 'test_axis_keyword: the input is not modified');
}
is(median([1, 2, 3]), 2, 'test_array_like: median([1, 2, 3])');
{
	my @a = (0 .. 23); $a[2] = 'NaN';
	isnan_(median(\@a), 'test_nan_behavior: a NaN anywhere gives NaN');
	@a = (0 .. 23); $a[23] = 'NaN';
	isnan_(median(\@a), 'test_nan_behavior: NaN at the end gives NaN');
}

#--------
# leaks
#--------
{
	my @a = (3, 1, 2, 5, 4, 6);
	no_leaks_ok { my $m = median(\@a) } 'median no leaks' unless $INC{'Devel/Cover.pm'};
}

done_testing();
