#!/usr/bin/env perl
#
# Cross-validation of chisq_test() against the two reference implementations,
# using their own documented examples and test suites rather than cases
# invented here.
#
# Provenance of every expected value below:
#
#   * R 4.6.1 stats::chisq.test() -- the function chisq_test() is modelled on.
#     Its statistic, df, p-value, expected frequencies and method string.
#     The cases marked "?chisq.test" are the examples in
#     src/library/stats/man/chisq.test.Rd, whose printed output is checked into
#     R's own tests/Examples/stats-Ex.Rout.save; the case marked PR#5701 is
#     from tests/reg-tests-1a.R.  Every number was re-generated under R 4.6.1
#     at 17 significant digits and is reproduced verbatim here, so this file
#     needs no R installation to run.
#   * SciPy 1.17.1 scipy.stats.chisquare() / scipy.stats.chi2_contingency() --
#     the cases in scipy/stats/tests/test_contingency.py and
#     test_stats.py::TestPowerDivergence, plus the worked examples in the
#     chisquare(), chi2_contingency() and association() docstrings.  SciPy's
#     own comments mark several of these "computed in R"; the rest were
#     re-run under SciPy 1.17.1 and agree with R to the tolerances below.
#
# t/chisq_test.t covers the Perl-side API -- input shapes, named options,
# argument validation, the small-expected-count warning and leak checking.
# This file is only about whether the numbers are right.
#
# Where the two references disagree, chisq_test() follows R.  The three places
# they part company are recorded explicitly at the end of this file, so that
# changing sides later has to be a deliberate act.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR 'chisq_test';

# Every case below with an expected count under 5 makes chisq_test() warn, the
# same way R does.  That warning is R's behaviour under test in its own right
# (see t/chisq_test.t), not noise to be fixed here, so it is collected rather
# than printed.
my @WARNINGS;
local $SIG{__WARN__} = sub { push @WARNINGS, $_[0] };

# Tolerances.  On this build every statistic and every expected frequency
# below is bit-for-bit identical to R's -- the worst disagreement across all
# of them is 1.6e-16, i.e. none -- because both sides build the margins and
# the sum the same way, in a long double accumulator (see ct_acc_t in
# LikeR.xs; a plain NV accumulator drifts a couple of ulp on any table with
# more than a handful of cells).  The p-values agree to 1.2e-14 relative at
# worst, which is the residual difference between R's pchisq() and the
# incomplete gamma function in LikeR.xs; that worst case is the p ~ 1e-45
# tail of the SciPy gh-10159 case, and everything less extreme sits nearer
# 1e-15.  The limits here sit a couple of orders above what this build needs,
# as headroom for the long-double and __float128 NV builds rather than as
# slack the double build is using.
my $TOL_STAT = 1e-13;
my $TOL_P    = 1e-12;
my $TOL_E    = 1e-13;

# Three cases below are 2x2 tables whose Yates correction is min(0.5, |O - E|)
# with all four |O - E| equal, so every corrected residual cancels and the
# statistic is exactly 0 -- and the p-value exactly 1 -- as real numbers.  What
# R prints for them (1.5e-24, 2.9e-32, 7.2e-32) is not a statistic, it is the
# leftover of forming E in floating point: the four |O - E| differ in their
# last bits, the minimum is a hair below the rest, and the residue gets
# squared and divided by the smallest expectation.  Its size is a property of
# the NV, not of the test -- a double build lands on R's value, and a
# __float128 build cancels the whole way to 0 -- so a relative compare against
# R's number can only ever pass on the width R happened to use.  Those cases
# are checked against 0 and 1 with the absolute tolerances below instead,
# which are still many orders tighter than any statistic that means anything.
my $TOL_ZERO_STAT = 1e-20;
my $TOL_UNIT_P    = 1e-11;

# Relative compare that also copes with an expected value of exactly 0.
sub near {
	my ($got, $want, $tol, $name) = @_;
	my $diff = abs($got - $want);
	my $rel  = $want == 0 ? $diff : $diff / abs($want);
	return 1 if $rel <= $tol;
	fail($name);
	diag("         got: $got\n    expected: $want\n    rel diff: $rel > $tol");
	return 0;
}

# One case: check statistic, df, p-value and method in a single test.  A case
# may override either tolerance with stat_tol/p_tol; the only ones that do are
# the exact-zero statistics described above.
sub check {
	my ($name, $res, $want) = @_;
	my $ok = 1;
	$ok &&= near($res->{statistic}{'X-squared'}, $want->{stat}, $want->{stat_tol} || $TOL_STAT, "$name: statistic");
	$ok &&= near($res->{'p.value'},              $want->{p},    $want->{p_tol}    || $TOL_P,    "$name: p-value");
	if ($res->{parameter}{df} != $want->{df}) {
		fail("$name: df");
		diag("         got: $res->{parameter}{df}\n    expected: $want->{df}");
		$ok = 0;
	}
	if (defined $want->{method} && $res->{method} ne $want->{method}) {
		fail("$name: method");
		diag("         got: $res->{method}\n    expected: $want->{method}");
		$ok = 0;
	}
	pass($name) if $ok;
	return $ok;
}

# Flatten a 1D or 2D 'expected' array ref, row-major.
sub flat_expected {
	my ($e) = @_;
	return map { ref $_ eq 'ARRAY' ? @$_ : $_ } @$e;
}

sub check_expected {
	my ($name, $res, @want) = @_;
	my @got = flat_expected($res->{expected});
	if (@got != @want) {
		fail("$name: expected frequencies");
		diag('         got ' . scalar(@got) . ' cells, wanted ' . scalar(@want));
		return 0;
	}
	for my $i (0 .. $#want) {
		near($got[$i], $want[$i], $TOL_E, "$name: expected cell $i") or return 0;
	}
	pass("$name: expected frequencies");
	return 1;
}

my $PEARSON = "Pearson's Chi-squared test";
my $YATES   = "Pearson's Chi-squared test with Yates' continuity correction";
my $GOF     = 'Chi-squared test for given probabilities';

# ======================================================================
# 1.  The examples on R's ?chisq.test man page
# ======================================================================
#
# Agresti (2007) p.39, the party-affiliation-by-gender table.  R:
#   M <- rbind(c(762, 327, 468), c(484, 239, 477))
#   chisq.test(M)
#   X-squared = 30.070149095754672, df = 2, p-value = 2.9535891832117569e-07
{
	my $M = [ [762, 327, 468], [484, 239, 477] ];
	my $res = chisq_test($M);
	check('?chisq.test Agresti 2x3', $res, {
		stat => 30.070149095754672, df => 2, p => 2.9535891832117569e-07,
		method => $PEARSON,
	});
	check_expected('?chisq.test Agresti 2x3', $res,
		703.67138193688788, 319.64526659412405, 533.68335146898801,
		542.32861806311212, 246.35473340587595, 411.31664853101199);

	# the same table with R's dimnames, as a hash of hashes
	my $H = {
		F => { Democrat => 762, Independent => 327, Republican => 468 },
		M => { Democrat => 484, Independent => 239, Republican => 477 },
	};
	my $hres = chisq_test($H);
	check('?chisq.test Agresti 2x3 (HoH)', $hres, {
		stat => 30.070149095754672, df => 2, p => 2.9535891832117569e-07,
		method => $PEARSON,
	});
	near($hres->{expected}{F}{Democrat},    703.67138193688788, $TOL_E, 'HoH expected F/Democrat')
		and pass('HoH expected F/Democrat');
	near($hres->{expected}{M}{Republican},  411.31664853101199, $TOL_E, 'HoH expected M/Republican')
		and pass('HoH expected M/Republican');
}

# 2x2 with the default correction.  R:
#   x <- matrix(c(12, 5, 7, 7), ncol = 2)   # i.e. rows (12,7) and (5,7)
#   chisq.test(x)$p.value   # 0.4233054
{
	my $res = chisq_test([ [12, 7], [5, 7] ]);
	check('?chisq.test 2x2 Yates', $res, {
		stat => 0.64112026389503174, df => 1, p => 0.42330542432241836,
		method => $YATES,
	});
	check_expected('?chisq.test 2x2 Yates', $res,
		10.419354838709678, 8.5806451612903221,
		6.5806451612903230, 5.4193548387096770);
}

# Goodness of fit on a named vector -- a 1D hash here.  R:
#   x <- c(A = 20, B = 15, C = 25); chisq.test(x)
#   X-squared = 2.5, df = 2, p-value = 0.28650479686019009
{
	my $res = chisq_test({ A => 20, B => 15, C => 25 });
	check('?chisq.test named GOF', $res, {
		stat => 2.5, df => 2, p => 0.28650479686019009, method => $GOF,
	});
	near($res->{expected}{$_}, 20, $TOL_E, "named GOF expected $_") for qw(A B C);
	pass('?chisq.test named GOF: expected frequencies');

	# and the same counts positionally
	my $ares = chisq_test([20, 15, 25]);
	check('?chisq.test named GOF (array)', $ares, {
		stat => 2.5, df => 2, p => 0.28650479686019009, method => $GOF,
	});
}

# Goodness of fit against explicit probabilities.  R:
#   x <- c(89,37,30,28,2); p <- c(0.40,0.20,0.20,0.19,0.01)
#   chisq.test(x, p = p)
#   X-squared = 5.7947085455574419, df = 4, p-value = 0.21501309592078605
#   Warning: Chi-squared approximation may be incorrect   (E[5] = 1.86)
{
	my $x = [89, 37, 30, 28, 2];
	my $res = chisq_test($x, p => [0.40, 0.20, 0.20, 0.19, 0.01]);
	check('?chisq.test GOF with p', $res, {
		stat => 5.7947085455574419, df => 4, p => 0.21501309592078605,
		method => $GOF,
	});
	check_expected('?chisq.test GOF with p', $res,
		74.400000000000006, 37.200000000000003, 37.200000000000003,
		35.340000000000003, 1.8600000000000001);

	# ... and against the same probabilities given as unnormalised weights.
	# R: chisq.test(x, p = c(40,20,20,15,5), rescale.p = TRUE)
	#    X-squared = 9.9901433691756267, df = 4, p-value = 0.040594043344781221
	my $rres = chisq_test($x, p => [40, 20, 20, 15, 5], 'rescale.p' => 1);
	check('?chisq.test rescale.p', $rres, {
		stat => 9.9901433691756267, df => 4, p => 0.040594043344781221,
		method => $GOF,
	});
	# the underscore spelling is the same option
	my $ures = chisq_test($x, p => [40, 20, 20, 15, 5], rescale_p => 1);
	is($ures->{statistic}{'X-squared'}, $rres->{statistic}{'X-squared'},
		'rescale_p is an alias for rescale.p');

	# R errors rather than rescaling silently:
	#   chisq.test(x, p = c(40,20,20,15,5))
	#   Error: probabilities must sum to 1.
	my $err = !eval { chisq_test($x, p => [40, 20, 20, 15, 5]); 1 };
	ok($err, 'probabilities that do not sum to 1 are fatal without rescale.p');
	like($@, qr/probabilities must sum to 1/, '... with R\'s message');

	# uniform p is the default, and stating it changes nothing.
	# R: chisq.test(x)  ->  X-squared = 109.10752688172043, df = 4
	my $flat = chisq_test($x);
	check('?chisq.test uniform GOF', $flat, {
		stat => 109.10752688172043, df => 4, p => 1.1280154699877185e-22,
		method => $GOF,
	});
	my $expl = chisq_test($x, p => [0.2, 0.2, 0.2, 0.2, 0.2]);
	near($expl->{statistic}{'X-squared'}, $flat->{statistic}{'X-squared'}, $TOL_STAT,
		'explicit uniform p reproduces the default') and pass('explicit uniform p');
}

# ======================================================================
# 2.  R's own regression suite
# ======================================================================
#
# tests/reg-tests-1b.R, the over-long-deparse case: x and y are both
# rep(c(1000,1001,1002), each = 5), so table(x, y) is 5 on the diagonal of a
# 3x3 and 0 elsewhere.  R: X-squared = 29.999999999999996, df = 4.
{
	my $res = chisq_test([ [5, 0, 0], [0, 5, 0], [0, 0, 5] ]);
	check('reg-tests-1b 3x3 diagonal', $res, {
		stat => 29.999999999999996, df => 4, p => 4.894437128029221e-06,
		method => $PEARSON,
	});
	check_expected('reg-tests-1b 3x3 diagonal', $res,
		(5 / 3) x 9);
}

# tests/reg-tests-1a.R PR#5701 used matrix(23171, 2, 2) to catch an infinite
# loop in the simulation path.  A table that sits exactly on its expectation
# has statistic 0 -- and, because Yates' correction is then min(0.5, 0) = 0, R
# reports it as a plain Pearson test even though correct = TRUE was in force.
{
	my $res = chisq_test([ [23171, 23171], [23171, 23171] ]);
	check('reg-tests-1a PR#5701 flat 2x2', $res, {
		stat => 0, df => 1, p => 1, method => $PEARSON,
	});
}

# ======================================================================
# 3.  SciPy's chi2_contingency test cases
# ======================================================================
#
# test_contingency.py::test_expected_freq and the chi2_contingency() docstring
# share this table.  SciPy: statistic 2.7777777777777777,
# pvalue 0.24935220877729619, dof 2, expected [[12,12,16],[18,18,24]].
{
	my $res = chisq_test([ [10, 10, 20], [20, 20, 20] ]);
	check('SciPy chi2_contingency 2x3', $res, {
		stat => 2.7777777777777777, df => 2, p => 0.24935220877729619,
		method => $PEARSON,
	});
	check_expected('SciPy chi2_contingency 2x3', $res, 12, 12, 16, 18, 18, 24);
}

# test_contingency.py::test_chi2_contingency_trivial -- a table whose rows are
# proportional, so expected == observed exactly.  correction=False.
{
	my $res = chisq_test([ [1, 2], [1, 2] ], correct => 0);
	check('SciPy trivial 2x2, no correction', $res, {
		stat => 0, df => 1, p => 1, method => $PEARSON,
	});
	check_expected('SciPy trivial 2x2, no correction', $res, 1, 2, 1, 2);
}

# test_contingency.py::test_chi2_contingency_yates_gh13875 -- the regression
# that pinned Yates' correction to min(0.5, |O - E|) so it can never overshoot
# and make the statistic negative.  SciPy asserts p is 1 to rtol 1e-12.  The
# correction is |O - E| = 12/1580 in all four cells, so the exact statistic is
# 0 and the exact p is 1; R's double build prints the rounding leftovers
# X-squared = 1.4515367733818938e-24, p = 0.99999999999903866, which is why
# this one is checked absolutely (see $TOL_ZERO_STAT above).
{
	my $res = chisq_test([ [1573, 3], [4, 0] ]);
	check('SciPy gh-13875 Yates cap', $res, {
		stat => 0, df => 1, p => 1, method => $YATES,
		stat_tol => $TOL_ZERO_STAT, p_tol => $TOL_UNIT_P,
	});
	cmp_ok(abs($res->{'p.value'} - 1), '<', 1e-12, 'SciPy gh-13875: p is 1 to rtol 1e-12');
}

# test_contingency.py::test_exact_permutation, whose reference statistic is the
# uncorrected Pearson value of np.arange(4).reshape(2,2).
{
	my $res = chisq_test([ [0, 1], [2, 3] ], correct => 0);
	check('SciPy arange 2x2, no correction', $res, {
		stat => 0.59999999999999998, df => 1, p => 0.43857802608099994,
		method => $PEARSON,
	});
	check_expected('SciPy arange 2x2, no correction', $res,
		0.33333333333333331, 0.66666666666666663,
		1.6666666666666667,  3.3333333333333335);
}

# chi2_contingency() docstring, correction=False: pvalue 0.0614122539870913.
{
	my $res = chisq_test([ [12, 3], [17, 16] ], correct => 0);
	check('SciPy chi2_contingency docstring, no correction', $res, {
		stat => 3.4988285761425506, df => 1, p => 0.061412253987091006,
		method => $PEARSON,
	});
	# and with the correction R restores by default
	my $yres = chisq_test([ [12, 3], [17, 16] ]);
	check('SciPy chi2_contingency docstring, Yates', $yres, {
		stat => 2.4091074080184787, df => 1, p => 0.12063113097759662,
		method => $YATES,
	});
}

# test_contingency.py::test_assoc -- SciPy pins Cramer's V at
# 0.09222412010290792 for this 3x5 table, and V^2 * n * min(r-1, c-1) is the
# Pearson statistic, so the value is a SciPy-side check of the same number R
# reports as X-squared = 3.6062422513923686.
{
	my $tab = [ [12, 13, 14, 15, 16], [17, 16, 18, 19, 11], [9, 15, 14, 12, 11] ];
	my $res = chisq_test($tab);
	check('SciPy test_assoc 3x5', $res, {
		stat => 3.6062422513923686, df => 8, p => 0.89078961107660215,
		method => $PEARSON,
	});
	my $n = 0;
	$n += $_ for map { @$_ } @$tab;
	my $cramer = sqrt($res->{statistic}{'X-squared'} / ($n * 2));
	near($cramer, 0.09222412010290792, 1e-13, 'SciPy test_assoc: Cramer V round-trip')
		and pass('SciPy test_assoc: Cramer V round-trip');
}

# association() docstring, the 4x2 table.  SciPy's Pearson contingency
# coefficient is 0.18303298140595667 = sqrt(X2 / (X2 + n)).
{
	my $tab = [ [100, 150], [203, 322], [420, 700], [320, 210] ];
	my $res = chisq_test($tab);
	check('SciPy association 4x2', $res, {
		stat => 84.056068718619628, df => 3, p => 4.1376973625861407e-18,
		method => $PEARSON,
	});
	my $n = 0;
	$n += $_ for map { @$_ } @$tab;
	my $X2 = $res->{statistic}{'X-squared'};
	near(sqrt($X2 / ($X2 + $n)), 0.18303298140595667, 1e-13,
		'SciPy association: Pearson coefficient round-trip')
		and pass('SciPy association: Pearson coefficient round-trip');
}

# test_morestats.py::test_median_test_basic builds this 2x2 and checks it
# against chi2_contingency with and without the correction.
{
	check('SciPy median_test 2x2, Yates', chisq_test([ [1, 2], [4, 2] ]), {
		stat => 0.056250000000000001, df => 1, p => 0.81252426931536859,
		method => $YATES,
	});
	check('SciPy median_test 2x2, no correction', chisq_test([ [1, 2], [4, 2] ], correct => 0), {
		stat => 0.90000000000000002, df => 1, p => 0.34278171114791145,
		method => $PEARSON,
	});
}

# ======================================================================
# 4.  SciPy's chisquare / power_divergence goodness-of-fit cases
# ======================================================================
#
# test_stats.py::TestPowerDivergence power_div_1d_cases: f_obs = [4,8,12,8]
# against a uniform expectation gives 4, and against f_exp = [2,16,12,2]
# gives 24.  (SciPy checks the p-value as chi2.sf(stat, k - 1 - ddof).)
{
	check('SciPy power_divergence uniform', chisq_test([4, 8, 12, 8]), {
		stat => 4, df => 3, p => 0.26146412994911072, method => $GOF,
	});
	# f_exp is a vector of counts summing to n, i.e. p = f_exp / n
	check('SciPy power_divergence f_exp',
		chisq_test([4, 8, 12, 8], p => [2, 16, 12, 2], 'rescale.p' => 1), {
		stat => 24, df => 3, p => 2.4979977724652009e-05, method => $GOF,
	});
	# the same probabilities pre-normalised
	check('SciPy power_divergence f_exp (normalised)',
		chisq_test([4, 8, 12, 8], p => [2/32, 16/32, 12/32, 2/32]), {
		stat => 24, df => 3, p => 2.4979977724652009e-05, method => $GOF,
	});
	# f_obs == f_exp, so every term of the sum is 0
	check('SciPy power_divergence zero statistic',
		chisq_test([3, 5, 7, 9], p => [3, 5, 7, 9], 'rescale.p' => 1), {
		stat => 0, df => 3, p => 1, method => $GOF,
	});
}

# test_stats.py::test_power_divergence_gh_12282, axis=0 column slices:
# obs [10,30] vs exp [5,35] -> 5.71428571, and obs [20,20] vs exp [15,25] ->
# 2.66666667, with p-values 0.01682741 and 0.10247043.
{
	check('SciPy gh-12282 column 1',
		chisq_test([10, 30], p => [5, 35], 'rescale.p' => 1), {
		stat => 5.7142857142857144, df => 1, p => 0.016827409482756819, method => $GOF,
	});
	check('SciPy gh-12282 column 2',
		chisq_test([20, 20], p => [15, 25], 'rescale.p' => 1), {
		stat => 2.666666666666667, df => 1, p => 0.1024704348597493, method => $GOF,
	});
}

# test_stats.py::test_chiquare_data_types_attributes, the gh-10159 / gh-18368
# integer-overflow regression: obs [n, 0] against exp [n/2, n/2] must give
# exactly n.  The second one drives the p-value into hard underflow.
{
	check('SciPy gh-10159 uint8', chisq_test([200, 0], p => [0.5, 0.5]), {
		stat => 200, df => 1, p => 2.0884875837625449e-45, method => $GOF,
	});
	my $big = chisq_test([1000000, 0], p => [0.5, 0.5]);
	near($big->{statistic}{'X-squared'}, 1000000, 1e-13, 'SciPy gh-18368 int32: statistic')
		and pass('SciPy gh-18368 int32: statistic');
	is($big->{'p.value'}, 0, 'SciPy gh-18368 int32: p underflows to 0, as in R');
}

# chisquare() docstring: [16,18,16,14,12,12] uniform -> 2.0 / 0.84914503608461,
# and against f_exp [16,16,16,16,16,8] -> 3.5 / 0.62338762774958.
{
	check('SciPy chisquare docstring, uniform', chisq_test([16, 18, 16, 14, 12, 12]), {
		stat => 2, df => 5, p => 0.84914503608460967, method => $GOF,
	});
	check('SciPy chisquare docstring, f_exp',
		chisq_test([16, 18, 16, 14, 12, 12], p => [16, 16, 16, 16, 16, 8], 'rescale.p' => 1), {
		stat => 3.5, df => 5, p => 0.6233876277495819, method => $GOF,
	});
	# the same counts flattened out of a 6x2 matrix, SciPy's axis=None case:
	# obs.ravel() -> 23.310344827586206, p 0.01597569253412758 on df 11
	check('SciPy chisquare docstring, axis=None',
		chisq_test([16, 18, 16, 14, 12, 12, 32, 24, 16, 28, 20, 24]), {
		stat => 23.310344827586206, df => 11, p => 0.015975692534127565, method => $GOF,
	});
}

# ======================================================================
# 5.  A 1 x k or k x 1 table is a goodness-of-fit test, as in R
# ======================================================================
#
# R's chisq.test() opens with
#     if (is.matrix(x)) { if (min(dim(x)) == 1L) x <- as.vector(x) }
# so a single-row or single-column matrix never reaches the contingency-table
# branch.  chisq_test() does the same, and only the shape of 'expected'
# still remembers how the data was passed in.
{
	my $want = { stat => 10, df => 2, p => 0.0067379469990854671, method => $GOF };
	check('1 x 3 matrix collapses to GOF', chisq_test([ [10, 20, 30] ]), $want);
	check('3 x 1 matrix collapses to GOF', chisq_test([ [10], [20], [30] ]), $want);
	check('plain 3-vector',                chisq_test([10, 20, 30]),        $want);

	my $res = chisq_test([ [10, 20, 30] ]);
	is(ref $res->{expected},     'ARRAY', '1 x 3: expected keeps the input nesting');
	is(ref $res->{expected}[0],  'ARRAY', '1 x 3: ... including the inner row');
	is_deeply($res->{expected},  [[20, 20, 20]], '1 x 3: expected values');
	is_deeply(chisq_test([ [10], [20], [30] ])->{expected}, [[20], [20], [20]],
		'3 x 1: expected values');

	# hashes collapse the same way, keyed by whichever axis is not 1
	my $h = chisq_test({ only => { A => 10, B => 20, C => 30 } });
	check('1-row hash of hashes collapses to GOF', $h, $want);
	is_deeply($h->{expected}, { only => { A => 20, B => 20, C => 20 } },
		'1-row HoH: expected keeps the input nesting');
	check('1-column hash of hashes collapses to GOF',
		chisq_test({ A => { n => 10 }, B => { n => 20 }, C => { n => 30 } }), $want);
}

# ======================================================================
# 6.  Yates' correction, in detail
# ======================================================================
#
# R computes YATES <- min(0.5, abs(x - E)) once for the whole table and only
# calls the test corrected when that minimum is positive.
{
	# |O - E| = 0.2 everywhere, so the correction is 0.2, not 0.5, and the
	# corrected statistic is exactly 0.
	# R: X-squared = 2.9347503914472165e-32, p-value = 0.99999999999999989
	my $res = chisq_test([ [1, 2], [3, 4] ]);
	check('Yates clamped to |O - E|', $res, {
		stat => 0, df => 1, p => 1, method => $YATES,
		stat_tol => $TOL_ZERO_STAT, p_tol => $TOL_UNIT_P,
	});
	cmp_ok($res->{statistic}{'X-squared'}, '<', $TOL_ZERO_STAT, '... statistic is 0 to rounding');

	# |O - E| = 1, so the correction is the full 0.5.
	# R: chisq.test(matrix(c(3,1,1,3), nrow=2)) -> 0.5, p = 0.47950012218695348
	check('Yates at the 0.5 cap', chisq_test([ [3, 1], [1, 3] ]), {
		stat => 0.5, df => 1, p => 0.47950012218695348, method => $YATES,
	});
	check('... and the same table uncorrected', chisq_test([ [3, 1], [1, 3] ], correct => 0), {
		stat => 2, df => 1, p => 0.15729920705028447, method => $PEARSON,
	});

	# a 2x2 sitting exactly on its expectation: correction 0, so R drops the
	# "with Yates' continuity correction" from the method string.
	check('zero correction reports a plain Pearson test', chisq_test([ [10, 20], [20, 40] ]), {
		stat => 0, df => 1, p => 1, method => $PEARSON,
	});

	# correct => 1 is the default, not a different code path
	is(chisq_test([ [10, 15], [20, 5] ], correct => 1)->{statistic}{'X-squared'},
	   chisq_test([ [10, 15], [20, 5] ])->{statistic}{'X-squared'},
	   'correct => 1 is the default');

	# R: chisq.test(rbind(c(10,15),c(20,5)))          -> 6.75,     p = 0.0093747684594348776
	#    chisq.test(rbind(c(10,15),c(20,5)), FALSE)   -> 8.3333.., p = 0.0038924171227786297
	check('2x2 corrected',   chisq_test([ [10, 15], [20, 5] ]), {
		stat => 6.75, df => 1, p => 0.0093747684594348776, method => $YATES,
	});
	check('2x2 uncorrected', chisq_test([ [10, 15], [20, 5] ], correct => 0), {
		stat => 8.3333333333333339, df => 1, p => 0.0038924171227786297, method => $PEARSON,
	});

	# the correction is 2x2-only; a 2x3 ignores it entirely
	is(chisq_test([ [10, 10, 20], [20, 20, 20] ], correct => 0)->{statistic}{'X-squared'},
	   chisq_test([ [10, 10, 20], [20, 20, 20] ])->{statistic}{'X-squared'},
	   'correct has no effect outside a 2x2');
}

# ======================================================================
# 7.  Non-integer counts, and the far tail of the distribution
# ======================================================================
#
# R never requires integers -- only nonnegative finite numbers -- so weighted
# tables go through unchanged.
{
	check('non-integer GOF', chisq_test([10.5, 20.25, 30.25]), {
		stat => 9.5922131147540988, df => 2, p => 0.0082618515549269019, method => $GOF,
	});
	# |O - E| = 1/6 in all four cells, so this is another exact zero; R's
	# double build prints X-squared = 7.1842689582627857e-32,
	# p-value = 0.99999999999999978.
	check('non-integer 2x2', chisq_test([ [1.5, 2.5], [3.5, 4.5] ]), {
		stat => 0, df => 1, p => 1, method => $YATES,
		stat_tol => $TOL_ZERO_STAT, p_tol => $TOL_UNIT_P,
	});
	# a p-value 60 orders down, to exercise the incomplete gamma tail
	# R: chisq.test(rbind(c(1000,2000,3000),c(4000,5000,6000)))
	check('large counts, tiny p', chisq_test([ [1000, 2000, 3000], [4000, 5000, 6000] ]), {
		stat => 279.99999999999994, df => 2, p => 1.5804200602736579e-61, method => $PEARSON,
	});
	# and a 4x4, for a df well above 2
	check('4x4 table', chisq_test([ [5, 10, 15, 20], [25, 30, 35, 40],
	                                [45, 50, 55, 60], [65, 70, 75, 80] ]), {
		stat => 6.3676540937624706, df => 9, p => 0.7026322183782383, method => $PEARSON,
	});
	# a zero cell is fine as long as its expectation is not zero
	check('GOF with a zero cell', chisq_test([0, 10, 20]), {
		stat => 20, df => 2, p => 4.5399929762484854e-05, method => $GOF,
	});
}

# ======================================================================
# 8.  Where R and SciPy disagree -- chisq_test() follows R
# ======================================================================
#
# (a) A 1 x k table.  R collapses it to a vector and tests goodness of fit
#     (df = k - 1); SciPy's chi2_contingency keeps it as a table, which makes
#     expected == observed, the statistic 0 and dof 0.  Section 5 above pins
#     R's answer; this records that the SciPy answer is the one being turned
#     down, and why -- dof 0 gives p = 1 for every input, which is no test.
{
	my $res = chisq_test([ [10, 20, 30] ]);
	isnt($res->{parameter}{df}, 0, 'a 1 x k table is not given df 0 (SciPy) ...');
	is($res->{parameter}{df},   2, '... but df = k - 1, as in R');
}

# (b) A zero row or column.  R divides by an expected count of 0 and returns
#     NaN with a warning; SciPy raises ValueError.  chisq_test() returns NaN,
#     and because min(0.5, |O - E|) is then 0 the method string stays plain
#     Pearson -- exactly what R prints.
{
	my $res = chisq_test([ [0, 0], [10, 20] ]);
	ok($res->{statistic}{'X-squared'} != $res->{statistic}{'X-squared'},
		'zero row gives a NaN statistic, as in R (SciPy raises)');
	ok($res->{'p.value'} != $res->{'p.value'}, '... and a NaN p-value');
	is($res->{parameter}{df}, 1, '... with df still 1');
	is($res->{method}, $PEARSON, '... reported as a plain Pearson test');
	is_deeply($res->{expected}, [[0, 0], [10, 20]], '... expected counts as R computes them');
}

# (c) A non-finite entry.  R's check is any(x < 0) || anyNA(x), which lets an
#     Inf through and returns NaN/NA from it; its own error message promises
#     "nonnegative and finite", and SciPy rejects it.  chisq_test() rejects it
#     too -- the one place this file's answer is neither reference's.
{
	my $inf = 9**9**9;
	ok(!eval { chisq_test([10, $inf, 30]); 1 }, 'an infinite count is fatal (R would return NaN)');
	like($@, qr/nonnegative and finite/, '... with R\'s wording');
}

# Every small-expected-count warning raised above was R's, and there should
# have been nothing else.
{
	my @other = grep { !/Chi-squared approximation may be incorrect/ } @WARNINGS;
	is_deeply(\@other, [], 'no warnings beyond the expected-count one R also gives');
	cmp_ok(scalar(@WARNINGS), '>', 0, 'the small-expected-count cases did warn');
}

done_testing();
