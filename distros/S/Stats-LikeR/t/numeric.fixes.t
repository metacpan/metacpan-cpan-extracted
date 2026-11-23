#!/usr/bin/env perl
#
# Regression tests for the 0.3428 numerical fixes.
#
# Provenance of the expected values:
#   * binom_test p-values: R 4.6.1 binom.test(4503599627370497, 9007199254740991,
#     alternative = "less"), and the same with 4503599627370498 and "greater",
#     options(digits = 17).  R's two-sided test cannot run at this n ("result
#     would be too long a vector"), so none is pinned.
#   * density(n =): R 4.6.1 length(density(c(1,2,3,5,8), n = n)$x), whose grid is
#     seq.int(from, to, length.out = n.user) and so takes ceil(n)
#     (src/library/stats/R/density.R line 179; src/main/seq.c).
#   * qt(): R 4.6.1 qt(), options(digits = 17).
#   * pbinom(1765184560411, 17785315992617, 7151671909757000 * 2**-56, lower = FALSE):
#     mpmath 1.x at mp.dps = 60, as the regularized incomplete beta
#     I_p(k + 1, n - k) by its defining integral; 0.0111407611194404998427.
#     Before 0.3428 a long double perl returned 0.0111407611194407632609
#     (rel 2.4e-14): ib_lambda() rounded (a + b) y before it cancelled against b.
#   * epi_2x2 on [[0,0],[5,5]]: epitools 0.5-10.1 riskratio()/oddsratio() with
#     method "wald" apply no correction and compute 0/0 = NaN for the empty row
#     (riskratio.wald.R: est <- (a1/n1)/(a0/n0)).
require 5.010;
use strict;
use warnings FATAL => 'all';
use Config;
use Test::More;
use Test::Exception;
use Stats::LikeR qw(binom_test density qt pbinom epi_2x2);

my $iv8 = $Config{ivsize} >= 8;

# binom_test: integer counts are read exactly.
SKIP: {
	skip 'needs 64-bit IVs', 13 unless $iv8;
	my $r = binom_test(4503599627370497, 9007199254740991, alternative => 'less');
	# 1e-10 relative: the p-value is the incomplete beta at 4.5e15 shapes, good to ~1e-12 on a double
	cmp_ok(abs($r->{p_value} - 0.50000001681415984), '<=', 1e-10, 'odd count in [2**52, 2**53) is accepted (less)');
	is($r->{statistic}, '4503599627370497', 'statistic is exact');
	is($r->{parameter}, '9007199254740991', 'parameter is exact');
	$r = binom_test(4503599627370498, 9007199254740991, alternative => 'greater');
	cmp_ok(abs($r->{p_value} - 0.4999999831858401), '<=', 1e-10, 'greater');
	$r = binom_test(9007199254740993, 9007199254740993);
	is($r->{statistic}, '9007199254740993', 'x past 2**53 is exact');
	is($r->{parameter}, '9007199254740993', 'n past 2**53 is exact');
	$r = binom_test(499999999999999000, 499999999999999999);
	is($r->{statistic}, '499999999999999000', '499999999999999000 is not rounded to ...998976');
	is($r->{parameter}, '499999999999999999', 'n = 499999999999999999 is exact');
	$r = binom_test('9007199254740993', '9007199254740993');
	is($r->{statistic}, '9007199254740993', 'a string spelling an integer is exact too');
	# the stated limit and the test agree: IV_MAX - 1 passes, IV_MAX is refused
	lives_ok { binom_test(3, 9223372036854775806) } 'n = IV_MAX - 1 is accepted';
	throws_ok { binom_test(3, 9223372036854775807) } qr/n is too large \(the limit is 9223372036854775806\)/,
		'n = IV_MAX is refused with the limit that was just accepted';
	throws_ok { binom_test(-1, 10) } qr/x must be a nonnegative integer/, 'a negative integer is refused';
}
{
	my $lim = $Config{ivsize} >= 8 ? '9223372036854775806' : '2147483646';
	lives_ok { binom_test(3, $lim) } "n = $lim is accepted";
	throws_ok { binom_test(3, 1e30) } qr/n is too large/, 'n = 1e30 is refused as too large';
	my $r = binom_test(3.0000000001, 10);
	is($r->{statistic}, 3, 'a count within 1e-7 of an integer still rounds');
	throws_ok { binom_test(2.5, 10) } qr/x must be a nonnegative integer/, 'a fraction is refused';
}

# density: n is rounded up, as seq.int(length.out =) does.
{
	my @x = (1, 2, 3, 5, 8);
	my %want = (0.5 => 1, 1 => 1, 1.5 => 2, 2.5 => 3, 513.2 => 514);
	for my $n (sort { $a <=> $b } keys %want) {
		my $d = density(\@x, n => $n);
		is(scalar @{ $d->{x} }, $want{$n}, "density n => $n gives $want{$n} points");
		is(scalar @{ $d->{y} }, $want{$n}, "... and as many densities");
	}
	throws_ok { density(\@x, n => 0) } qr/'n' must be at least 1/, 'n => 0 croaks';
	throws_ok { density(\@x, n => -1) } qr/'n' must be at least 1/, 'n => -1 croaks';
	# 2**31 and 2**32 wrapped through SvIV() on a 32-bit IV perl into "must be at least 1"
	throws_ok { density(\@x, n => 2147483648) } qr/'n' is too large/, 'n => 2**31 is too large';
	throws_ok { density(\@x, n => 4294967296) } qr/'n' is too large/, 'n => 2**32 is too large';
}

# qt: a quantile past what an NV holds is -Inf at once; the rest agree with R.
{
	# qt(1e-300, 0.1) is about -1.6e2996: past a double (R: -Inf), inside a long double or __float128
	for my $c ([1e-300, 0.01], [1e-20, 0.001], ($Config{nvsize} > 8 ? () : [1e-300, 0.1])) {
		is(qt(@$c), -9**9**9, "qt($c->[0], $c->[1]) is -Inf, as R");
	}
	if ($Config{nvsize} > 8) {
		my $q = qt(1e-300, 0.1);
		ok($q < -1e300 && $q == $q && $q > -9**9**9, "qt(1e-300, 0.1) = $q is finite on a wide NV");
	}
	my @r = (
		[ [1e-300, 1],            -3.183098861837907e+299 ],
		[ [1e-50, 30],            -232.84591679865159 ],
		[ [-1e5, 1e3, log => 1],  -8.4634803810659208e+44 ],
		[ [0.3, 0.5],             -1.0095258786071923 ],
	);
	for my $c (@r) {
		my ($args, $want) = @$c;
		# 1e-9 relative: the worst disagreement with R here is 1e-13 (qt's own stop test)
		cmp_ok(abs(qt(@$args) / $want - 1), '<=', 1e-9, "qt(@$args)");
	}
}

# pbinom at shapes of 1e13, where (a + b) y - b lost sqrt(n) epsilon.
{
	my $got = pbinom(1765184560411, 17785315992617, 7151671909757000 * 2**-56, lower => 0);
	my $truth = 0.0111407611194404998427;
	# a wide NV (long double or __float128) is now good to 1e-17 here; a double to 7e-15, held to 1e-12
	my $tol = $Config{nvsize} > 8 ? 1e-16 : 1e-12;
	cmp_ok(abs($got / $truth - 1), '<=', $tol, 'pbinom upper tail at n = 1.8e13');
}

# epi_2x2: an empty exposure group has no risk.
{
	for my $t ([[0, 0], [5, 5]], [[5, 5], [0, 0]]) {
		my $e = epi_2x2($t);
		for my $k (qw(odds_ratio risk_ratio risk_diff nnt)) {
			ok($e->{$k} != $e->{$k}, "$k is NaN with an empty row");
		}
		ok($e->{risk_ratio_ci}[0] != $e->{risk_ratio_ci}[0], 'risk_ratio_ci is NaN');
	}
	my $e = epi_2x2([[0, 0], [5, 5]]);
	ok($e->{risk_exposed} != $e->{risk_exposed}, 'the empty group risk is NaN');
	is($e->{risk_unexposed}, 0.5, 'the other group risk is still 0.5');
	# a zero cell in a non-empty group keeps the documented +0.5 correction
	my $z = epi_2x2(0, 10, 5, 10);
	is($z->{correction}, 1, 'a zero cell still applies the correction');
	ok($z->{odds_ratio} == $z->{odds_ratio}, 'and is finite');
}

done_testing();
