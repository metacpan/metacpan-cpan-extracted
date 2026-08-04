#!/usr/bin/env perl
#
# Cross-validation of t_test() against the reference implementations.
#
# Every expected value below was produced by one of:
#
#   * R 4.x stats::t.test, options(digits=17)
#   * a case lifted from R's own regression suite
#     (r-source/tests/reg-tests-1a.R, "t.test with one group of size one")
#   * a case lifted from scipy/stats/tests/test_stats.py
#     (TestTTest_1samp, TestTTest_ind.test_special_cases,
#      test_ttest_rel_ci_1d, test_1samp_ci_1d, test_pvalue_ci)
#
# The TODO blocks at the bottom are cases where t_test() currently disagrees
# with R.  They are marked TODO rather than deleted so the divergence stays
# visible and `make test` stays green.

require 5.010;
use warnings FATAL => 'all';
use strict;
use Stats::LikeR;
use Test::Exception;
use Test::More;

sub is_approx {
	my ($got, $expected, $test_name, $epsilon) = @_;
	$epsilon = 1e-7 unless defined $epsilon;
	my $diff = abs($got - $expected);
	if ($diff <= $epsilon) {
		pass("$test_name (within $epsilon)");
		return 1;
	}
	fail($test_name);
	diag("         got: $got\n    expected: $expected; diff = $diff");
	return 0;
}

# compare statistic/df/p_value/conf_int in one shot
sub cmp_t {
	my ($lbl, $got, $exp, $eps_stat, $eps_ci) = @_;
	$eps_stat = 1e-12 unless defined $eps_stat;
	$eps_ci   = 1e-7  unless defined $eps_ci;
	is_approx( $got->{statistic}, $exp->{t},  "$lbl: statistic", $eps_stat );
	is_approx( $got->{df},        $exp->{df}, "$lbl: df",        $eps_stat );
	is_approx( $got->{p_value},   $exp->{p},  "$lbl: p_value",   $eps_stat );
	foreach my $j (0, 1) {
		my $want = $exp->{conf_int}[$j];
		if ($want == 9**9**9 || $want == -9**9**9) {
			is( $got->{conf_int}[$j], $want, "$lbl: conf_int[$j] is infinite" );
		} else {
			is_approx( $got->{conf_int}[$j], $want, "$lbl: conf_int[$j]", $eps_ci );
		}
	}
}

my $INF = 9**9**9;

#---------------------------------------------------------------------------
# scipy TestTTest_1samp -- the class comment says these were "Recomputed
# statistics and p-values with R t.test".  X1 = [-1,0,1], X2 = [0,1,2].
# t_test() had no n=3 / df=2 one-sample case at all.
#---------------------------------------------------------------------------
my @X1 = (-1, 0, 1);
my @X2 = (0, 1, 2);

cmp_t( 'scipy X1 mu=0', t_test(\@X1, mu => 0), {
	t => 0, df => 2, p => 1,
	conf_int => [-2.48413771175033, 2.48413771175033] });

cmp_t( 'scipy X1 mu=1', t_test(\@X1, mu => 1), {
	t => -1.73205080756888, df => 2, p => 0.225403330758517,
	conf_int => [-2.48413771175033, 2.48413771175033] });

cmp_t( 'scipy X1 mu=2', t_test(\@X1, mu => 2), {
	t => -3.46410161513775, df => 2, p => 0.0741799002274485,
	conf_int => [-2.48413771175033, 2.48413771175033] });

cmp_t( 'scipy X2 mu=0', t_test(\@X2, mu => 0), {
	t => 1.73205080756888, df => 2, p => 0.225403330758517,
	conf_int => [-1.48413771175033, 3.48413771175033] });

# scipy asserts P1_1_l == P1_1/2 and P1_1_g == 1 - P1_1/2
cmp_t( 'scipy X1 mu=1 less', t_test(\@X1, mu => 1, alternative => 'less'), {
	t => -1.73205080756888, df => 2, p => 0.112701665379258,
	conf_int => [-$INF, 1.68585446084705] });

cmp_t( 'scipy X1 mu=1 greater', t_test(\@X1, mu => 1, alternative => 'greater'), {
	t => -1.73205080756888, df => 2, p => 0.887298334620742,
	conf_int => [-1.68585446084705, $INF] });

is_approx( t_test(\@X1, mu => 1, alternative => 'less')->{p_value},
           t_test(\@X1, mu => 1)->{p_value} / 2,
           'one-sided p is half the two-sided p (t < 0)', 1e-14 );
is_approx( t_test(\@X1, mu => 1, alternative => 'greater')->{p_value},
           1 - t_test(\@X1, mu => 1)->{p_value} / 2,
           'other-sided p is 1 - half the two-sided p', 1e-14 );

#---------------------------------------------------------------------------
# scipy test_1samp_ci_1d -- one-sample CI at a NON-default conf_level for all
# three alternatives.  01.t only exercises conf_level != 0.95 two-sided.
#---------------------------------------------------------------------------
my @sx = (2.75532884, 0.93892217, 0.94835861, 1.49489446, -0.62396595,
          -1.88019867, -1.55684465, 4.88777104, 5.15310979, 4.34656348);

cmp_t( 'scipy 1samp conf=0.85 two.sided', t_test(\@sx, conf_level => 0.85), {
	t => 2.01327620559185, df => 9, p => 0.0749308674958793,
	conf_int => [0.359442321170914, 2.93334550282909] });

cmp_t( 'scipy 1samp conf=0.85 less', t_test(\@sx, conf_level => 0.85, alternative => 'less'), {
	t => 2.01327620559185, df => 9, p => 0.96253456625206,
	conf_int => [-$INF, 2.54570720326284] });

cmp_t( 'scipy 1samp conf=0.85 greater', t_test(\@sx, conf_level => 0.85, alternative => 'greater'), {
	t => 2.01327620559185, df => 9, p => 0.0374654337479396,
	conf_int => [0.747080620737163, $INF] });

#---------------------------------------------------------------------------
# scipy test_ttest_rel_ci_1d -- PAIRED CI, non-default conf_level, all three
# alternatives.  01.t only checks the paired CI at the default 0.95 two-sided.
#---------------------------------------------------------------------------
my @px = (1.22825792, 1.63950485, 4.39025641, 0.68609437, 2.03813481,
          -1.20040109, 1.81997937, 1.86854636, 2.94694282, 3.94291373);
my @py = (3.49961496, 1.53192536, 5.53620083, 2.91687718, 0.04858043,
          3.78505943, 3.3077496, 2.30468892, 3.42168074, 0.56797592);

cmp_t( 'scipy paired conf=0.85 two.sided',
	t_test(\@px, \@py, paired => 1, conf_level => 0.85), {
	t => -1.02904527870904, df => 9, p => 0.330318965177796,
	conf_int => [-1.912194489914035, 0.400169725914035] });

cmp_t( 'scipy paired conf=0.85 less',
	t_test(\@px, \@py, paired => 1, conf_level => 0.85, alternative => 'less'), {
	t => -1.02904527870904, df => 9, p => 0.165159482588898,
	conf_int => [-$INF, 0.05192005631147523] });

cmp_t( 'scipy paired conf=0.85 greater',
	t_test(\@px, \@py, paired => 1, conf_level => 0.85, alternative => 'greater'), {
	t => -1.02904527870904, df => 9, p => 0.834840517411102,
	conf_int => [-1.563944820311475, $INF] });

#---------------------------------------------------------------------------
# mu != 0 for the TWO-SAMPLE and PAIRED branches.  01.t only ever passes mu
# with a single sample, so the (mx - my - mu) / stderr path and the
# "CI is centred on the estimate, not on mu" behaviour were both untested.
#---------------------------------------------------------------------------
my @a = (27.5,21.0,19.0,23.6,17.0,17.9,16.9,20.1,21.9,22.6,23.1,19.6,19.0,21.7,21.4);
my @b = (27.1,22.0,20.8,23.4,23.4,23.5,25.8,22.0,24.8,20.2,21.9,22.1,22.9,20.5,24.4);

cmp_t( 'Welch mu=-2', t_test(\@a, \@b, mu => -2), {
	t => -0.188873569098925, df => 24.9885292902314, p => 0.851717534939828,
	conf_int => [-3.98409626714093, -0.349237066192406] });

cmp_t( 'Student mu=-2', t_test(\@a, \@b, mu => -2, var_equal => 1), {
	t => -0.188873569098925, df => 28, p => 0.851554272023792,
	conf_int => [-3.97423133507401, -0.359101998259322] });

cmp_t( 'paired mu=-2', t_test(\@a, \@b, mu => -2, paired => 1), {
	t => -0.206593428832664, df => 14, p => 0.839301832442614,
	conf_int => [-3.89694652119117, -0.436386812142165] });

cmp_t( 'paired mu=-2 greater',
	t_test(\@a, \@b, mu => -2, paired => 1, alternative => 'greater'), {
	t => -0.206593428832664, df => 14, p => 0.580349083778693,
	conf_int => [-3.58758160551298, $INF] });

# mu must shift the statistic but not the interval
{
	my $r0 = t_test(\@a, \@b);
	my $r1 = t_test(\@a, \@b, mu => -2);
	is_approx( $r0->{conf_int}[$_], $r1->{conf_int}[$_],
		"two-sample conf_int[$_] is independent of mu", 1e-12 ) for 0, 1;
	is_approx( $r1->{statistic}, $r0->{statistic} + 2 / (($r0->{estimate_x} - $r0->{estimate_y}) / $r0->{statistic}),
		'two-sample statistic shifts by mu/stderr', 1e-9 );
}

#---------------------------------------------------------------------------
# Badly unbalanced samples -- Welch df far from any integer, and n=3 vs n=12.
#---------------------------------------------------------------------------
cmp_t( 'Welch n=12 vs n=3', t_test([1..12], [20,21,25]), {
	t => -8.38552760240712, df => 4.12653425574648, p => 0.00096473286778298,
	conf_int => [-20.5705737577882, -10.4294262422118] });

cmp_t( 'Student n=12 vs n=3', t_test([1..12], [20,21,25], var_equal => 1), {
	t => -6.90969963490353, df => 13, p => 1.06950693597465e-05,
	conf_int => [-20.3461895515724, -10.6538104484276] });

#---------------------------------------------------------------------------
# df = 1 -- the heaviest possible tail, where the t quantile is enormous.
#---------------------------------------------------------------------------
cmp_t( 'df=1', t_test([1, 3], mu => 0), {
	t => 2, df => 1, p => 0.295167235300866,
	conf_int => [-10.7062047361747, 14.7062047361747] }, 1e-12, 1e-6 );

#---------------------------------------------------------------------------
# Tiny p-values.  R: t.test(rnorm(200, mean=5), mu=0) with set.seed(1) and
# t.test(1:28).  A two-sided p of 1e-149 must not be flushed to zero, and the
# "wrong side" one-sided p must be exactly 1, not 1 + epsilon.
#---------------------------------------------------------------------------
cmp_t( 'R t.test(1:28)', t_test([1..28]), {
	t => 9.32737905308881, df => 27, p => 6.18853891804438e-10,
	conf_int => [11.3102998366822, 17.6897001633178] }, 1e-12, 1e-7 );

{
	# a deterministic large-t construction: mean 5, sd 1, n = 200
	my @o = map { 5 + sin($_) * 0.5 } 1 .. 200;
	my $r  = t_test(\@o, mu => 0);
	my $rg = t_test(\@o, mu => 0, alternative => 'greater');
	my $rl = t_test(\@o, mu => 0, alternative => 'less');
	cmp_ok( $r->{p_value},  '>', 0, 'huge t: two-sided p does not underflow to 0' );
	cmp_ok( $r->{p_value},  '<', 1e-100, 'huge t: two-sided p is astronomically small' );
	is_approx( $rg->{p_value}, $r->{p_value} / 2, 'huge t: greater p is half two-sided', 1e-300 );
	is( $rl->{p_value}, 1, 'huge t: wrong-tail p is exactly 1' );
	cmp_ok( $rl->{p_value}, '<=', 1, 'p_value never exceeds 1' );
}

#---------------------------------------------------------------------------
# scipy test_pvalue_ci -- the duality between a one-sided p-value and the
# one-sided interval.  If L is the lower bound of the 'greater' interval at
# confidence c, then testing mu = L one-sided must return p = 1 - c.
#---------------------------------------------------------------------------
foreach my $c (0.6, 0.8, 0.9, 0.95, 0.99) {
	my $g = t_test(\@sx, mu => 0, alternative => 'greater', conf_level => $c);
	my $p = t_test(\@sx, mu => $g->{conf_int}[0], alternative => 'greater')->{p_value};
	is_approx( $p, 1 - $c, "greater: p at the CI lower bound is 1 - $c", 1e-8 );

	my $l = t_test(\@sx, mu => 0, alternative => 'less', conf_level => $c);
	my $q = t_test(\@sx, mu => $l->{conf_int}[1], alternative => 'less')->{p_value};
	is_approx( $q, 1 - $c, "less: p at the CI upper bound is 1 - $c", 1e-8 );
}

#---------------------------------------------------------------------------
# Zero-variance / degenerate inputs.  scipy's
# TestTTest_ind.test_special_cases pins each of these; R raises
# "data are essentially constant" where scipy returns nan/inf.
#---------------------------------------------------------------------------
dies_ok { t_test([0, 0, 0], [1, 1, 1]) }
	'both samples constant dies (scipy: t = -inf, R: error)';
dies_ok { t_test([0, 0, 0], [1, 1, 1], var_equal => 1) }
	'both samples constant dies with var_equal';
dies_ok { t_test([1..10], [1..10], paired => 1) }
	'paired with identical samples dies (scipy: nan, R: nan)';

# only ONE sample constant is perfectly legal -- R gives a finite answer
cmp_t( 'one sample constant', t_test([5, 5, 5], [1, 2, 3]), {
	t => 5.19615242270663, df => 2, p => 0.0350987186459846,
	conf_int => [0.51586228824967, 5.48413771175033] });

#---------------------------------------------------------------------------
# Argument-handling coverage that 01.t does not reach.
#---------------------------------------------------------------------------
throws_ok { t_test([1..5], 'y' => [1..5], 'bogus' => 1) }
	qr/unknown argument 'bogus'/, 'unknown named argument dies';
throws_ok { t_test([5]) }
	qr/needs at least 2 elements/, 'single-element x dies';
throws_ok { t_test([1..5], conf_level => 0) }
	qr/'conf_level' must be between 0 and 1/, 'conf_level = 0 dies';
throws_ok { t_test([1..5], conf_level => 1) }
	qr/'conf_level' must be between 0 and 1/, 'conf_level = 1 dies';
throws_ok { t_test('x' => 'not a ref') }
	qr/must be an ARRAY reference/, 'non-reference x dies';

# positional and named forms must agree everywhere, including with options
{
	my $pos = t_test(\@a, \@b, var_equal => 1, conf_level => 0.9, alternative => 'less');
	my $nam = t_test('x' => \@a, 'y' => \@b, var_equal => 1, conf_level => 0.9, alternative => 'less');
	is_approx( $pos->{$_}, $nam->{$_}, "positional == named: $_", 0 )
		for qw(statistic df p_value estimate_x estimate_y);
	is( $pos->{conf_int}[$_], $nam->{conf_int}[$_], "positional == named: conf_int[$_]" )
		for 0, 1;
}

# the returned key set differs between the one/two sample branches
{
	my $one = t_test([1..10], mu => 3);
	ok(  exists $one->{estimate},   'one-sample returns estimate' );
	ok( !exists $one->{estimate_x}, 'one-sample has no estimate_x' );
	my $two = t_test(\@a, \@b);
	ok(  exists $two->{estimate_x} && exists $two->{estimate_y}, 'two-sample returns estimate_x/estimate_y' );
	ok( !exists $two->{estimate},   'two-sample has no estimate' );
	my $par = t_test(\@a, \@b, paired => 1);
	ok(  exists $par->{estimate},   'paired returns estimate (the mean difference)' );
	is_approx( $par->{estimate}, $two->{estimate_x} - $two->{estimate_y},
		'paired estimate equals the difference of the means', 1e-12 );
}

#===========================================================================
# Cases where t_test() used to disagree with stats::t.test.  Every expected
# value here is R's.  Kept as ordinary tests so a regression is a failure.
#===========================================================================

#---------------------------------------------------------------------------
# undef is dropped, not coerced to 0.  R's t.test filters with !is.na(), and
# for a paired test with complete.cases(x, y), so a pair goes whole.
#---------------------------------------------------------------------------
{
	my @xn = (1, 2, undef, 4, 5);
	my @yn = (2, undef, 3, 4, 9);

	# R: t.test(c(1,2,NA,4,5))
	cmp_t( 'undef dropped, one-sample', t_test(\@xn), {
		t => 3.286335345031, df => 3, p => 0.0462050913533633,
		conf_int => [0.0948372842452347, 5.90516271575477] }, 1e-10 );

	# R drops NA per sample for an unpaired test: nx = 4, ny = 4
	cmp_t( 'undef dropped, two-sample', t_test(\@xn, \@yn), {
		t => -0.832050294337844, df => 4.84909670563231, p => 0.444410236260585,
		conf_int => [-6.17789673698985, 3.17789673698985] }, 1e-10 );

	# R uses complete.cases for a paired test: only pairs 1, 4 and 5 survive
	cmp_t( 'incomplete pairs dropped whole', t_test(\@xn, \@yn, paired => 1), {
		t => -1.38675049056307, df => 2, p => 0.299859957985995,
		conf_int => [-6.83781167920893, 3.5044783458756] }, 1e-10 );

	# a NaN counts as NA in R too (is.na(NaN) is TRUE)
	my $nan = 9**9**9 - 9**9**9;
	is_approx( t_test([1, 2, $nan, 4, 5])->{df}, 3, 'NaN dropped like undef', 0 );

	# and an all-undef sample has nothing left to test
	throws_ok { t_test([undef, undef, undef]) }
		qr/needs at least 2 elements/, 'an all-undef sample dies';
}

#---------------------------------------------------------------------------
# A sample of one.  From R's own regression suite, reg-tests-1a.R:4530,
# "t.test with one group of size one":
#   x <- 1:10; t.test(y=x[1], x=x[-1], var.equal=TRUE)
# With var.equal the pooled variance skips the n=1 group -- it contributes no
# sum of squares -- so the test is well defined.  Welch needs a variance from
# each side and R refuses.
#---------------------------------------------------------------------------
cmp_t( 'R reg-test: var_equal, ny=1', t_test([2..10], [1], var_equal => 1), {
	t => 1.73205080756888, df => 8, p => 0.121502918817113,
	conf_int => [-1.65686054106258, 11.6568605410626] }, 1e-10 );

cmp_t( 'R reg-test: var_equal, nx=1', t_test([1], [2..10], var_equal => 1), {
	t => -1.73205080756888, df => 8, p => 0.121502918817113,
	conf_int => [-11.6568605410626, 1.65686054106258] }, 1e-10 );

throws_ok { t_test([2..10], [1]) }
	qr/not enough 'y' observations/, 'Welch with ny=1 dies rather than returning NaN';
throws_ok { t_test([1], [2..10]) }
	qr/not enough 'x' observations/, 'Welch with nx=1 dies rather than returning NaN';
throws_ok { t_test([1..10], []) }
	qr/not enough 'y' observations/, 'an empty y dies rather than returning NaN';
throws_ok { t_test([1], [2], var_equal => 1) }
	qr/not enough observations/, 'var_equal with nx=ny=1 dies (df would be 0)';
throws_ok { t_test([1, 2], [3], paired => 1) }
	qr/Paired arrays must be same length/, 'paired length mismatch still dies';
throws_ok { t_test([1, undef], [3, 4], paired => 1) }
	qr/not enough complete pairs/, 'paired with one complete pair dies';

#---------------------------------------------------------------------------
# 'alternative' is validated, as R's match.arg() does.  Falling through to a
# two-sided test answers a question nobody asked.
#---------------------------------------------------------------------------
throws_ok { t_test([1..10], alternative => 'foobar') }
	qr/'alternative' must be/, 'an unrecognised alternative dies';
throws_ok { t_test([1..10], alternative => 'gerater') }
	qr/'alternative' must be/, "a typo'd 'greater' dies rather than becoming two.sided";
throws_ok { t_test([1..10], alternative => '') }
	qr/'alternative' must be/, 'an empty alternative dies';

# scipy spells it "two-sided" and R spells it "two.sided"; both are accepted
foreach my $spelling (qw(two.sided two-sided two_sided)) {
	is_approx( t_test([1..10], alternative => $spelling)->{p_value},
		t_test([1..10])->{p_value}, "alternative => '$spelling' is two-sided", 0 );
}

#---------------------------------------------------------------------------
# One-sided intervals at conf_level < 0.5 need a NEGATIVE t quantile, which a
# search running upward from zero cannot produce.
#---------------------------------------------------------------------------
cmp_t( 'conf_level=0.3 less', t_test([1..10], mu => 5, conf_level => 0.3, alternative => 'less'), {
	t => 0.522232967867094, df => 9, p => 0.692941372595803,
	conf_int => [-$INF, 4.9796572843017] });

cmp_t( 'conf_level=0.3 greater', t_test([1..10], mu => 5, conf_level => 0.3, alternative => 'greater'), {
	t => 0.522232967867094, df => 9, p => 0.307058627404197,
	conf_int => [6.0203427156983, $INF] });

# at conf_level exactly 0.5 the one-sided bound sits on the estimate
{
	my $h = t_test([1..10], conf_level => 0.5, alternative => 'greater');
	is_approx( $h->{conf_int}[0], 5.5, 'conf_level=0.5: bound is the estimate', 1e-12 );
}

#---------------------------------------------------------------------------
# "Essentially constant" is relative to the data's magnitude, as in R:
# stderr < 10 * .Machine$double.eps * abs(mean).  An absolute test lets through
# a spread a double cannot resolve at that scale: these four values around 1e10
# differ by 1e-5 and used to report t = 4e15, p = 3e-47.
#---------------------------------------------------------------------------
dies_ok { t_test([1e10, 1e10, 1e10, 1e10 + 1e-5]) }
	'rounding noise on a large mean is rejected as constant';
dies_ok { t_test([0, 0, 0]) }
	'an all-zero sample dies rather than returning NaN (R returns NaN)';
dies_ok { t_test([1e10, 1e10, 1e10, 1e10 + 1e-5], [2e10, 2e10, 2e10]) }
	'two-sample noise is scaled by the larger mean';

# but a spread that IS resolvable is a real test -- R: t=40031864895807.9, df=3
{
	my $r = t_test([1, 1, 1, 1 + 1e-13]);
	cmp_ok( $r->{statistic}, '>', 3.9e13, 'a resolvable tiny spread is still tested' );
	is_approx( $r->{df}, 3, 'resolvable tiny spread: df', 0 );
}

#---------------------------------------------------------------------------
# The t quantile no longer saturates at 1e6, and its accuracy no longer
# degrades with the data's scale (it used to stop at an absolute 1e-8, which
# is 1e-8 * std_err on the interval).
#---------------------------------------------------------------------------
# How tightly these two can be pinned is set by the ARGUMENT, not by the
# quantile.  conf_level arrives as a float, so the tail has to be recovered as
# (1 - conf_level) / 2, and that subtraction has already thrown away most of the
# tail it is trying to represent: the nearest *double* to 0.99999999 puts the
# tail at 5.0000000251e-9 rather than 5e-9, a relative error of 5.0e-9, and for
# conf_level = 0.9999999999 the error is 8.3e-8.  Since qt(p, 1) ~ 1/(pi * p),
# the quantile inherits that relative error exactly -- there is no way to get it
# back, because the information was gone before t_test() was called.
#
# That makes the answer depend on the build's NV, and the perls here bracket it:
#
#   perl 5.44.0 ($Config{nvtype} eq 'double')      qt -> 63661976.9168721
#   perl 5.12.5 ($Config{nvtype} eq 'long double') qt -> 63661977.2367910
#   the true qt(5e-9, 1, lower.tail = FALSE)             63661977.2367581
#
# The long-double build represents 0.99999999 to 19 digits, recovers the tail
# correctly and lands 5e-13 from the truth; the double build is 5.0e-9 out, which
# is exactly its tail's error.  Both are right for the precision they were
# handed, so pinning either one to 15 digits pins an artifact of the local NV.
# The reference below is therefore R's quantile at the tail actually intended,
# compared RELATIVELY with room for the representation error.
#   R: qt(5e-9,  1, lower.tail = FALSE) -> 63661977.236758128
#   R: qt(5e-11, 1, lower.tail = FALSE) -> 6366197723.6758127
{
	# relative comparison; $tol has to exceed the tail's own representation error
	my $rel_ci_ok = sub {
		my ($got, $want, $lbl, $tol) = @_;
		my $err = abs($got - $want) / abs($want);
		return pass("$lbl (rel err $err <= $tol)") if $err <= $tol;
		fail($lbl);
		diag("         got: $got\n    expected: $want\n     rel err: $err");
	};

	foreach my $c (
		{ conf_level => 0.99999999,   qt => 63661977.236758128,  tol => 2e-8  },
		{ conf_level => 0.9999999999, qt => 6366197723.6758127,  tol => 2e-7  },
	) {
		my $lbl = "conf_level=$c->{conf_level}, df=1";
		my $r   = t_test([1, 3], conf_level => $c->{conf_level});
		is_approx( $r->{statistic}, 2, "$lbl: statistic", 1e-12 );
		is_approx( $r->{df},        1, "$lbl: df",        1e-12 );
		is_approx( $r->{p_value},   0.295167235300866, "$lbl: p_value", 1e-12 );
		# mean is 2 and std_err is 1 for [1, 3], so the bounds are 2 -/+ qt
		$rel_ci_ok->($r->{conf_int}[0], 2 - $c->{qt}, "$lbl: conf_int[0]", $c->{tol});
		$rel_ci_ok->($r->{conf_int}[1], 2 + $c->{qt}, "$lbl: conf_int[1]", $c->{tol});
	}

	# The point of the two cases: the quantile must not saturate. A 100x smaller
	# tail is a ~100x wider interval, and the old 1e6 ceiling returned the SAME
	# interval for both, i.e. a ratio of 1. The two intervals carry their own
	# tails' representation errors (5.0e-9 and 8.3e-8), so the ratio is 100 to
	# about 8e-6 on a double NV and to 2e-8 on a long double one; 1e-3 covers
	# both and still rejects saturation by five orders of magnitude.
	my $narrow = t_test([1, 3], conf_level => 0.99999999);
	my $wide   = t_test([1, 3], conf_level => 0.9999999999);
	my $ratio  = ($wide->{conf_int}[1] - 2) / ($narrow->{conf_int}[1] - 2);
	is_approx( $ratio, 100, 'a 100x smaller tail widens the interval 100x', 1e-3 );
}

# the interval must be accurate RELATIVE to the data, at every scale.
# R: t.test((1:10)*s) -> (3.3341494103318308*s, 7.6658505896681692*s)
foreach my $s (1, 1e3, 1e6, 1e9) {
	my $r = t_test([map { $_ * $s } 1 .. 10]);
	is_approx( $r->{conf_int}[0] / $s, 3.3341494103318308,
		"conf_int lower bound is scale-free at scale $s", 1e-13 );
	is_approx( $r->{conf_int}[1] / $s, 7.6658505896681692,
		"conf_int upper bound is scale-free at scale $s", 1e-13 );
}

#---------------------------------------------------------------------------
# A defined but non-array 'y' is a mistake, not a one-sample test.
#---------------------------------------------------------------------------
throws_ok { t_test([1..10], 'y' => 5) }
	qr/'y' must be an ARRAY reference/, 'a scalar y dies rather than being dropped';
throws_ok { t_test([1..10], 'y' => { a => 1 }) }
	qr/'y' must be an ARRAY reference/, 'a hash ref y dies';

# an explicit undef y is R's default y = NULL: a one-sample test
is_approx( t_test([1..10], 'y' => undef)->{p_value}, t_test([1..10])->{p_value},
	'y => undef means a one-sample test', 0 );

done_testing();
