#!/usr/bin/env perl
#
# Cross-validation of ks_test() against the two reference implementations,
# using their own test suites and man-page examples rather than cases invented
# here.  t/ks_test.t already covers the six argument-parsing/aliasing bugs it
# was written for; this file does not repeat them.
#
# Provenance of every expected value below:
#
#   * R 4.6.1 (2026-06-24) stats::ks.test() -- the function ks_test() is
#     modelled on.  ks_test()'s statistic is R's D / D^+ / D^-, its
#     exact/asymptotic auto-gate is R's (n.x*n.y < 10000 two-sample, n < 100
#     one-sample), its exact two-sample p-value is R's psmirnov_exact_uniq_upper
#     lattice DP, and its asymptotic p-values are R's K2l series and
#     exp(-2*n*q^2).  The @R_TWO and @R_ONE tables were generated from R at
#     options(digits=17) by t/ks_test.R.scipy.R, which is committed next to
#     this file; re-run it with `Rscript t/ks_test.R.scipy.R`.
#   * R's own suite: the Hollander & Wolfe (1999) Example 5.4 pair from
#     tests/reg-tests-1a.R (PR#1004, "exact KS test gave incorrect results due
#     to rounding errors", pinned there as D = 0.6 and p = 15/286), and
#     ks.test(1:5, c(2.5,4.5)) from tests/reg-tests-1b.R (pinned as
#     p = 20/21).
#   * R's documented examples, whose printed output is pinned in
#     tests/Examples/stats-Ex.Rout.save: the Schroeer & Trenkler (1995) tied
#     pair and the airquality Ozone-by-Month pair from
#     src/library/stats/man/ks.test.Rd, and the Switzer (1976) knee-angle data
#     plus the set.seed(1) rnorm pair from man/qqplot.Rd.
#   * SciPy 1.17.1 scipy/stats/tests/test_stats.py -- TestKSTwoSamples
#     (testSmall, testTwoVsThree, testTwoVsFour, testEqualSizes, test100_100,
#     test100_110, testLarge) and TestKSOneSample (test_agree_with_r, itself
#     annotated "comparing with some values from R", and test_known_examples).
#     Those classes' own hardcoded expectations are reproduced verbatim in
#     @SCIPY_TWO and @SCIPY_ONE, so this file fails if either reference is
#     contradicted rather than only if R is.  t/ks_test.R.scipy.py regenerates
#     the SciPy side and dumps the one random fixture (@KN); re-run it with
#     `python3 t/ks_test.R.scipy.py`.
#   * mpmath at mp.dps = 80, used as the tie-breaker where R and ks_test()
#     disagree, and to measure how much accuracy the exact one-sample path
#     loses to cancellation.  t/ks_test.mpmath.py regenerates both sets of
#     numbers; see @MP_TWO and $TOL_P_ABS.
#
# Nothing here runs R or Python: every number is a frozen literal.
#
# The references do not always agree with each other, and neither always
# agrees with ks_test().  Every such case is in @DIVERGE at the end of the
# file, asserted against *both* what ks_test() produces and what the reference
# produces, so that changing one is a deliberate act.  In summary:
#
#   1. Exact two-sample p-value with ties.  R 4.6 conditions the lattice DP on
#      the observed tie pattern (psmirnov(z = w)); ks_test() does not, and
#      instead warns and falls back to the asymptotic p-value.  This is a
#      missing feature, not a wrong answer: the warning is part of the
#      contract, and the fallback value is pinned.
#   2. Exact one-sided one-sample p-value.  R uses the Birnbaum & Tingey
#      (1951) formula; ks_test() warns, uses exp(-2*n*D^2), and reports the
#      asymptotic method string, since that is the p-value the caller got.
#   3. One-sample auto-gate with ties.  R's rule is (n < 100) && !TIES, so a
#      tied one-sample input goes asymptotic; ks_test() only tests n < 100 and
#      stays exact.  Its exact value matches R's exact=TRUE exactly.
#   4. Asymptotic two-sided two-sample p-value.  R calls its K2l series with
#      tol = 1e-6, which truncates the small-argument alternative series after
#      a single term; ks_test() passes 1e-9.  mpmath says ks_test() is right
#      to 8.9e-15 relative where R is off by up to 4.6e-6.  @MP_TWO therefore
#      pins mpmath's value, not R's, for that one path.  (ks_test()'s
#      *one-sample* two-sided asymptotic path does use 1e-6, matching R; that
#      inconsistency is pinned as-is in @R_ONE.)
#   5. R's psmirnov_asymp computes the upper tail as 1 - (1 - exp(-2*n*q^2)),
#      which cancels to exactly 0 once exp() drops below the double epsilon.
#      ks_test() evaluates exp() directly and keeps the value.
#   6. R's pkolmogorov_one_exact returns NaN for D = 0, because the
#      Birnbaum-Tingey sum takes log(q + j/n) at q = 0.
#   7. SciPy's ks_2samp ignores ties in exact mode, and its asymptotic mode is
#      not asymptotic: two-sided it evaluates kstwo.sf at finite n, one-sided
#      it applies Hodges' continuity correction.  So only SciPy's *exact*
#      no-tie values are directly comparable, and those are what @SCIPY_TWO
#      uses; the rest is in @DIVERGE.  SciPy's exact two-sided p-value also
#      floors at ~1e-15 (its own test file annotates the 10000x10001 case
#      "2.7755575615628914e-15"), which is why testLarge's two-sided
#      expectation is a divergence and its one-sided ones are not.
#   8. SciPy's ks_1samp ignores `mode` entirely for one-sided alternatives and
#      always returns the exact ksone survival function.
#   9. Not a divergence between implementations but between NV widths: the
#      exact two-sided one-sample p-value is 1 - K2x(n, D), and that
#      subtraction is pure cancellation, so the answer is absolutely but not
#      relatively accurate and the surviving digits depend on the build.  See
#      $TOL_P_ABS, which is the only absolute tolerance in the file and exists
#      solely for this.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR 'ks_test';

# Test::LeakTrace is optional, as in the sibling suites.  Both the import and
# the fallback stub happen in BEGIN so that no_leaks_ok's (&;$) prototype is
# known when the block-form call near the end of the file is compiled.
our $HAVE_LEAKTRACE;
BEGIN {
	$HAVE_LEAKTRACE = eval { require Test::LeakTrace; Test::LeakTrace->import('no_leaks_ok'); 1 };
	unless ($HAVE_LEAKTRACE) {
		no strict 'refs';
		*{'main::no_leaks_ok'} = sub (&;$) { SKIP: { skip 'Test::LeakTrace not installed', 1 } };
	}
}

# ---------------------------------------------------------------------------
# Tolerances.
#
# $TOL_D is absolute, not relative, because D is a difference of two ECDFs and
# so lives in [0, 1]: a relative limit would be meaningless for the many cases
# where the true D is 0 and R reports -6.9e-17 out of its own -min(z)
# cancellation.  Worst absolute disagreement over the 112 R-pinned rows -- 88 in
# @R_TWO plus 24 in @R_ONE -- is 1.1e-16, so 1e-14 leaves two orders of headroom
# for long-double and quadmath builds, where the ECDF divisions round
# differently.
my $TOL_D = 1e-14;

# $TOL_P is the relative p-value limit against R.  Worst observed over the
# same rows is 1.0e-15 -- the exact two-sample rows are in fact bit-identical
# to R, all 45 of them, because ks_test() runs the same lattice DP in the same
# order.  1e-11 is four orders of headroom.  It is not widened anywhere; the
# cases that need more than this are divergences, and they are in @DIVERGE.
my $TOL_P = 1e-11;

# $TOL_MP is the relative limit against mpmath for the asymptotic two-sided
# two-sample path.  Worst observed is 8.9e-15, on the 10000x110 case whose
# p-value is 2.7e-24, so the limit is dominated by the exp() underflow there
# rather than by the series.
my $TOL_MP = 1e-11;

# $TOL_SCIPY is the relative limit against SciPy's own frozen expectations.
# Worst observed is 1.6e-13 for everything up to 100x110.  SciPy's own bar for
# these is assert_array_almost_equal's decimal=6, i.e. absolute 1.5e-6, so this
# is five orders tighter than the reference demands of itself.
my $TOL_SCIPY = 1e-11;

# The 10000x110 rows are looser, and the loss is SciPy's: its exact one-sided
# p-value comes from _count_paths_outside_method, which sums binomial ratios in
# double, where ks_test() and R both run the lattice DP.  R and ks_test() agree
# to 1.9e-15 on those same two numbers (see @R_TWO's large.* rows); SciPy sits
# 7.6e-12 away from both.
my $TOL_SCIPY_BIG = 1e-10;

# $TOL_P_ABS is an *absolute* floor added on top of the relative limit, and it
# applies to exactly one path: the exact two-sided one-sample p-value, which
# both R and ks_test() form as 1 - K2x(n, D).  K2x returns the lower tail, so
# for a significant result that subtraction is pure cancellation and the answer
# is only absolutely accurate, never relatively.  mpmath at dps=80, running the
# same Marsaglia-Tsang-Wang recursion without the cancellation, puts the real
# damage at:
#
#   n=10, D=0.79343088086445324 (norm.hw): true 3.1106659123909613e-07, both
#         R and ks_test say 3.1106659148516513e-07 -- 7.9e-10 relative,
#         2.5e-16 absolute.
#   n=99, D=0.5039893563146316  (auto-gate): true 8.3461529953847775e-24, both
#         say 1.9984014443252818e-15 -- 2.4e+08 relative, 2.0e-15 absolute.
#
# So the reference value itself is a few ulps of 1 of pure noise, and no
# comparison against it can be tighter than that.  What the local NV matrix
# actually returns for those two rows makes the point better than any argument:
#
#   n=99   double (5.44.0/5.42.3/5.10.1): 1.9984014443252818e-15  (all noise)
#          long double (5.12.5):          exactly 0
#          __float128 (5.44.0-quadmath):  8.3461529969664625e-24  (1.9e-10 of
#                                         the true 8.3461529953847775e-24)
#   norm.hw double:      3.1106659148516513e-07
#          long double:  3.1106659123915966e-07
#          __float128:   3.1106659123909613e-07  (the true value, to all 17
#                                                 digits printed)
#
# In other words the wider builds are right and the frozen double reference is
# wrong, which is exactly the situation an absolute floor is for.  The largest
# gap any of them has from R is the n=99 long-double 0, i.e. R's whole
# 2.0e-15; 1e-14 is that with ~5x of room -- 45 ulps of 1, still far below any
# p-value a caller could interpret.
#
# The floor is a fixed double-epsilon figure rather than one scaled off the
# running perl's NV width, because what it is measuring is the accuracy of the
# frozen reference value, which was computed in double once and for all.  It is
# applied only to the 'E1' rows, the SciPy one-sample exact rows, the inline
# n=99 assertion and the inline tied-1-sample one; nothing else in the file
# gets an absolute floor.
my $TOL_P_ABS = 1e-14;

# ---------------------------------------------------------------------------
# Data.  Everything is either a literal from a reference's test file or built
# by lin(), which reproduces numpy.linspace / R's seq(length.out=) exactly:
# both compute start + (stop-start)*i/(n-1), not a repeated addition.
sub lin {
	my ($from, $to, $n) = @_;
	return ($from) if $n == 1;
	my @out;
	push @out, $from + ($to - $from) * $_ / ($n - 1) for 0 .. $n - 1;
	return @out;
}

# Hollander & Wolfe (1999) Example 5.4, from R's tests/reg-tests-1a.R.
my @HW_X = (-0.15, 8.6, 5, 3.71, 4.29, 7.74, 2.48, 3.25, -1.15, 8.38);
my @HW_Y = (2.55, 12.07, 0.46, 0.35, 2.69, -0.94, 1.73, 0.73, -0.35, -0.37);

# ks.test(1:5, c(2.5,4.5)) from R's tests/reg-tests-1b.R.
my @KS5_X = (1, 2, 3, 4, 5);
my @KS5_Y = (2.5, 4.5);

# Schroeer & Trenkler (1995), from R's ?ks.test.  Documented there as
# D = 3/7 with exact p = 8/33; both are in @DIVERGE, since the exact value
# needs the tie-conditional DP.
my @ST_X = (1, 2, 2, 3, 3);
my @ST_Y = (1, 2, 3, 3, 4, 5, 6);

# Switzer (1976) knee-angle data, from R's ?qqplot.  40 vs 40, heavily tied.
my @SW_F = (-31, -30, -25, -25, -23, -23, -22, -20, -20, -18,
            -18, -18, -16, -15, -15, -14, -13, -11, -10, - 9,
            - 8, - 7, - 7, - 7, - 6, - 6, - 4, - 4, - 3, - 2,
            - 2, - 1,   1,   1,   4,   5,  11,  12,  16,  34);
my @SW_M = (-31, -20, -18, -16, -16, -16, -15, -14, -14, -14,
            -14, -13, -13, -11, -11, -10, - 9, - 9, - 8, - 7,
            - 7, - 6, - 6,  -5, - 5, - 5, - 4, - 2, - 2, - 2,
              0,   0,   1,   1,   2,   4,   5,   5,   6,  17);

# airquality$Ozone for Month 5 and Month 8, from R's ?ks.test.  The NAs are
# kept as undef on purpose: R's ks.test drops them with x[!is.na(x)] before
# doing anything else, and ks_test() must reach the same 26-vs-26 comparison
# from the raw 31-element columns.
my @OZ5 = (
	41, 36, 12, 18, undef, 28, 23, 19, 8, undef, 7, 16, 11, 14, 18, 14, 34,
	6, 30, 11, 1, 11, 4, 32, undef, undef, undef, 23, 45, 115, 37
);
my @OZ8 = (
	39, 9, 16, 78, 35, 66, 122, 89, 110, undef, undef, 44, 28, 65, undef, 22,
	59, 23, 31, 44, 21, 9, undef, 45, 168, 73, undef, 76, 118, 84, 85
);

# R's ?qqplot "agreement with ks.test" example: set.seed(1); x <- rnorm(50);
# y <- rnorm(50, mean = .5, sd = .95).  R's own output pins p = 0.1123852.
my @QQ_X = (
	-0.62645381074233242, 0.18364332422208224, -0.83562861241004716,
	1.5952808021377916, 0.32950777181536051, -0.82046838411801526,
	0.48742905242848528, 0.73832470512921733, 0.57578135165349231,
	-0.30538838715635602, 1.511781168450848, 0.38984323641143109,
	-0.62124058054180376, -2.2146998871774999, 1.1249309181431082,
	-0.044933609015230851, -0.016190263098946087, 0.94383621068529922,
	0.82122119509808855, 0.59390132121750883, 0.91897737160821824,
	0.7821363007310671, 0.074564983365190601, -1.9893516958633728,
	0.61982574789471023, -0.056128739529000785, -0.1557955067053293,
	-1.4707523838992744, -0.47815005510862035, 0.41794156019970241,
	1.358679551529044, -0.10278772734299552, 0.38767161155936913,
	-0.05380504058290512, -1.3770595347557761, -0.41499456329821404,
	-0.39428995433736466, -0.059341813857006189, 1.1000253719838831,
	0.76317574948057103, -0.16452093011749421, -0.25336168133935138,
	0.69696338559861353, 0.55666320171291864, -0.68875569454952288,
	-0.70749515696020368, 0.36458196213683268, 0.76853292735353406,
	-0.11234620764802799, 0.88110471434941399
);
my @QQ_Y = (
	0.87820058634871456, -0.081425073588232699, 0.82406370685320351,
	-0.57289494127675278, 1.8613725166159851, 2.3813799035805667,
	0.15113959735681642, -0.49192789500070422, 1.0412336460702922,
	0.37169812631321686, 2.7815368724795375, 0.46272199740348924,
	1.155252394328238, 0.52660205084163281, -0.206109548438285,
	0.67935268453862574, -1.2147106974464859, 1.8922771184847416,
	0.64559067130130288, 2.5639810868405786, 1.1601020160644437,
	0.8330437548003022, 0.71368293752955896, -0.8646400872768383,
	1.2528904566546056, 0.90905227325108224, 0.10731561848974771,
	-1.0083690401572437, -0.24024579886695294, 0.31504952322152311,
	-0.058429271887547741, -0.19024930525265552, 0.29806129170502506,
	1.1136599357622356, 0.71155131550443161, 1.6404861025303236,
	1.4304069415072285, -0.16303075490677306, 0.5544300945281338,
	-0.20404723368864944, 0.19230515445118132, 0.98290081341220914,
	1.6003656567340693, -0.24371614069593628, 1.7000795357247876,
	1.7710350152102906, 0.42283644957938404, -0.35272391885422214,
	-0.7099144204705099, -0.20531983185830504
);

# scipy.stats.norm.rvs(loc=0.2, size=100, random_state=987654321) --
# TestKSOneSample.test_known_examples' fixture, dumped by
# t/ks_test.R.scipy.py.
my @KN = (
	2.4465508100784525, -0.44591822460231706, -0.9835769929205533,
	2.129492518817858, 0.26681398832628556, -0.7970597579031304,
	1.0153298266862043, -1.1409368139994727, 2.110636912944709,
	0.9095833978776484, 1.3293468863737936, -0.9395479656435199,
	0.5090553818225265, -0.3944667553822961, -0.891333343636163,
	0.5667021771118285, -0.18767771352710672, -1.4370159238474611,
	1.9259775971818385, 0.9850900029608995, -0.6366603010660623,
	0.6861717219670661, 1.019392131278331, 1.7569778964778204,
	0.6836776704316405, -1.6326505063122476, -0.883556344300426,
	-1.132366210261601, 0.6416504653515209, 2.293855674066512,
	-1.2322187053134563, 1.188241099789412, -0.09748080747337262,
	-0.09457710012771287, -0.9999731349703425, 0.05731793722581369,
	-1.5467771908703876, -0.23762604504920654, -1.0051662631830371,
	-0.4100664101396309, -0.0034528994746228503, 0.2853100086863099,
	2.0537259443054663, -0.4148272844918394, 0.2911513831331549,
	0.5670274092623371, 0.5372897804663352, -2.203574652513705,
	-0.8084648679276385, -0.15218364874213064, 0.7980301728289318,
	0.7730266016157743, 0.41565207597504183, -0.23621966426817875,
	0.4090280275180906, 0.6060172552716754, 0.08766702695467711,
	0.541138612214277, -1.235777021038127, 0.9192492790743985,
	1.222446145994394, 1.6636331311620673, 1.5752499834383358,
	-1.6852765076806786, 0.5791404848937878, 0.6271827533829194,
	1.871548806764746, 1.1334784317758413, -0.7864821988232544,
	0.07877675472365374, 0.07821517906776303, -1.1035155172893911,
	0.36741797124156694, 0.5794278743188345, 1.7284441595728435,
	0.7791014487956429, -0.3120849075744478, 0.5292986941380672,
	1.961672034398987, -0.19142618783807042, 0.04644176142027917,
	-0.5654107233959003, -1.7830579081582838, 0.18209506041237158,
	-0.5720904318495488, -0.81791857183849, 1.9219268491318704,
	-0.6600121152892708, 0.6415357665049237, 0.8045723553396624,
	1.8354151026932302, 0.8238783691780727, -0.14984604530882556,
	0.29712783409500765, 0.18299508992809163, 1.374306531779293,
	-2.2717645799061517, 0.4686280579980447, 0.16477610020254743,
	-0.4142100342195712
);

# SciPy's TestKSTwoSamples fixtures, reproduced exactly.
my @D1P    = map { $_ + 0.01 } (1.0, 2.0);
my @D1M    = map { $_ - 0.01 } (1.0, 2.0);
my @D2     = (1.0, 2.0, 3.0);
my @D2_P1  = map { $_ + 1   } @D2;
my @D2_P05 = map { $_ + 0.5 } @D2;
my @D2_M05 = map { $_ - 0.5 } @D2;
my @D2F    = (1.0, 2.0, 3.0, 4.0);
my @X100    = lin(1, 100, 100);
my @X100_P1 = map { $_ + 2 + 0.1 } @X100;
my @X100_M1 = map { $_ + 2 - 0.1 } @X100;
my @X110    = lin(1, 100, 110);
my @X110_P1 = map { $_ + 20 + 0.1 } @X110;
my @X110_M1 = map { $_ + 20 - 0.1 } @X110;
my @X2233 = ((2) x 3, (3) x 4, (5) x 5,  (6) x 4);
my @X3344 = map { $_ + 1 } @X2233;
my @X2356 = ((2) x 3, (3) x 4, (5) x 10, (6) x 4);
my @X3467 = ((3) x 10, (4) x 2, (6) x 10, (7) x 4);

# TestKSTwoSamples.testLarge: 10000 vs 110, with the half-lattice-step offset
# that keeps the pooled sample free of ties.
my ($LG_N1, $LG_N2) = (10000, 110);
my $LG_DELTA = 1 / $LG_N1 / $LG_N2 / 2 / 2;
my @LG_X = map { $_ - $LG_DELTA } lin(1, 200, $LG_N1);
my @LG_Y = lin(2, 100, $LG_N2);

# SciPy's TestKSOneSample fixtures.
my @SP1_A = lin(-1, 1, 9);
my @SP1_B = lin(-15, 15, 9);
my @SP1_C = (-1.23, 0.06, -0.60, 0.17, 0.66, -0.17, -0.08, 0.27, -0.98, -0.99);

# Degenerate shapes the references also cover.
my @ONE0  = (0);
my @ONE1  = (1);
my @ZERO5 = (0) x 5;
my @ONE5  = (1) x 5;
# TestKSTest.test_pm_inf_gh20386, re-run against pnorm: both infinities in one
# sample must not produce a NaN statistic or p-value.
my $INF   = 9**9**9;
my @PMINF = (-$INF, 0, 1, $INF);

my %DATA = (
	HW_X => \@HW_X, HW_Y => \@HW_Y, KS5_X => \@KS5_X, KS5_Y => \@KS5_Y,
	ST_X => \@ST_X, ST_Y => \@ST_Y, SW_F => \@SW_F, SW_M => \@SW_M,
	OZ5 => \@OZ5, OZ8 => \@OZ8, QQ_X => \@QQ_X, QQ_Y => \@QQ_Y, KN => \@KN,
	D1P => \@D1P, D1M => \@D1M, D2 => \@D2, D2F => \@D2F,
	D2_P1 => \@D2_P1, D2_P05 => \@D2_P05, D2_M05 => \@D2_M05,
	X100 => \@X100, X100_P1 => \@X100_P1, X100_M1 => \@X100_M1,
	X110 => \@X110, X110_P1 => \@X110_P1, X110_M1 => \@X110_M1,
	X2233 => \@X2233, X3344 => \@X3344, X2356 => \@X2356, X3467 => \@X3467,
	LG_X => \@LG_X, LG_Y => \@LG_Y,
	SP1_A => \@SP1_A, SP1_B => \@SP1_B, SP1_C => \@SP1_C,
	ONE0 => \@ONE0, ONE1 => \@ONE1, ZERO5 => \@ZERO5, ONE5 => \@ONE5,
	PMINF => \@PMINF,
);

# ---------------------------------------------------------------------------
# Helpers.

my %METHOD = (
	E2 => 'Two-sample Kolmogorov-Smirnov exact test',
	A2 => 'Two-sample Kolmogorov-Smirnov test (asymptotic)',
	E1 => 'One-sample Kolmogorov-Smirnov exact test',
	A1 => 'One-sample Kolmogorov-Smirnov test (asymptotic)',
);

my %WARN_RE = (
	ties => qr/cannot compute exact p-value with ties/,
	one1 => qr/exact 1-sample 1-sided KS test not implemented/,
	big  => qr/sample sizes too large for an exact p-value/,
);

# Call ks_test(), collecting warnings instead of letting them escape.  The
# file runs under `warnings FATAL => 'all'`, so a warning ks_test() is
# *supposed* to emit still has to be caught here rather than killing the test.
sub call_ks {
	my ($x, $y, %opt) = @_;
	my @warns;
	my $res;
	{
		local $SIG{__WARN__} = sub { push @warns, $_[0] };
		$res = ks_test($x, $y, %opt);
	}
	return ($res, \@warns);
}

# D lives in [0,1]: absolute limit.
sub d_ok {
	my ($got, $want, $label) = @_;
	my $ok = abs($got - $want) <= $TOL_D;
	ok($ok, "$label: D")
		or diag(sprintf "got %.17g want %.17g (abs diff %.3g > %.3g)",
			$got, $want, abs($got - $want), $TOL_D);
	return $ok;
}

# p-values span 1 down to 1e-26 here, so the limit is relative -- except at
# exactly 0, where only 0 will do, and on the one cancellation-bound path,
# where $abs (see $TOL_P_ABS) is allowed instead.
sub p_ok {
	my ($got, $want, $tol, $label, $abs) = @_;
	$abs = 0 unless defined $abs;
	my $diff = abs($got - $want);
	my $ok = $want == 0 ? $diff <= $abs
	                    : ($diff <= $tol * abs($want) || $diff <= $abs);
	ok($ok, "$label: p")
		or diag(sprintf "got %.17g want %.17g (diff %.3g; limit %.3g rel or %.3g abs)",
			$got, $want, $diff, $tol, $abs);
	return $ok;
}

# One corpus row: run it, check D, p, method string, alternative echo, and
# that exactly the expected warning (or none) came out.
sub run_row {
	my ($row, $p_tol) = @_;
	my ($label, $xn, $yn, $alt, $exact, $d_want, $p_want, $kind, $warn) = @$row;
	my $x = $DATA{$xn} or die "no such fixture '$xn'";
	my $y = $yn eq 'pnorm' ? 'pnorm' : ($DATA{$yn} or die "no such fixture '$yn'");
	my ($res, $warns) = call_ks($x, $y, alternative => $alt, exact => $exact);
	d_ok($res->{statistic}, $d_want, $label);
	# 'E1' is the 1 - K2x() path; see $TOL_P_ABS.
	p_ok($res->{p_value}, $p_want, $p_tol, $label,
		$kind eq 'E1' ? $TOL_P_ABS : 0);
	is($res->{method}, $METHOD{$kind}, "$label: method");
	is($res->{alternative}, $alt, "$label: alternative echoed");
	if ($warn) {
		my @hit = grep { $_ =~ $WARN_RE{$warn} } @$warns;
		is(scalar(@hit), 1, "$label: warns about '$warn'")
			or diag("warnings were: @$warns");
	}
	else {
		is(scalar(@$warns), 0, "$label: no warnings")
			or diag("warnings were: @$warns");
	}
	return $res;
}

# ---------------------------------------------------------------------------
# Corpus 1: every non-divergent case, against R 4.6.1.
#
# Generated by t/ks_test.R.scipy.R: all of the fixtures above crossed with
# alternative in (two.sided, greater, less) and exact in (TRUE, FALSE).  The
# columns are
#
#   label, x fixture, y fixture ('pnorm' for one-sample), alternative,
#   exact argument, expected D, expected p, expected method, expected warning
#
# The asymptotic two-sided two-sample rows are NOT here; see @MP_TWO for why.
my @R_TWO = (
	#  label                            x         y         alternative  ex   D                        p
	[ '100.100m1.greater.asymp',         'X100',   'X100_M1', 'greater',    0, 0.02,                    0.96078943915232318,     'A2', '' ],
	[ '100.100m1.greater.exact',         'X100',   'X100_M1', 'greater',    1, 0.02,                    0.96097845078625499,     'E2', '' ],
	[ '100.100m1.less.asymp',            'X100',   'X100_M1', 'less',       0, 0,                       1,                       'A2', '' ],
	[ '100.100m1.less.exact',            'X100',   'X100_M1', 'less',       1, 0,                       1,                       'E2', '' ],
	[ '100.100m1.two.sided.exact',       'X100',   'X100_M1', 'two.sided',  1, 0.02,                    1,                       'E2', '' ],
	[ '100.100p1.greater.asymp',         'X100',   'X100_P1', 'greater',    0, 0.029999999999999999,    0.91393118527122819,     'A2', '' ],
	[ '100.100p1.greater.exact',         'X100',   'X100_P1', 'greater',    1, 0.029999999999999999,    0.91432901142769896,     'E2', '' ],
	[ '100.100p1.less.asymp',            'X100',   'X100_P1', 'less',       0, 0,                       1,                       'A2', '' ],
	[ '100.100p1.less.exact',            'X100',   'X100_P1', 'less',       1, 0,                       1,                       'E2', '' ],
	[ '100.100p1.two.sided.exact',       'X100',   'X100_P1', 'two.sided',  1, 0.029999999999999999,    0.99999999999620548,     'E2', '' ],
	[ '100.110m1.greater.asymp',         'X100',   'X110_M1', 'greater',    0, 0.20818181818181825,     0.010669710775667363,    'A2', '' ],
	[ '100.110m1.greater.exact',         'X100',   'X110_M1', 'greater',    1, 0.20818181818181825,     0.0089019059582464404,   'E2', '' ],
	[ '100.110m1.less.asymp',            'X100',   'X110_M1', 'less',       0, 0,                       1,                       'A2', '' ],
	[ '100.110m1.less.exact',            'X100',   'X110_M1', 'less',       1, 0,                       1,                       'E2', '' ],
	[ '100.110m1.two.sided.exact',       'X100',   'X110_M1', 'two.sided',  1, 0.20818181818181825,     0.017803803861025598,    'E2', '' ],
	[ '100.110p1.greater.asymp',         'X100',   'X110_P1', 'greater',    0, 0.21090909090909091,     0.0094656428300557982,   'A2', '' ],
	[ '100.110p1.greater.exact',         'X100',   'X110_P1', 'greater',    1, 0.21090909090909091,     0.0078695943190544276,   'E2', '' ],
	[ '100.110p1.less.asymp',            'X100',   'X110_P1', 'less',       0, 0,                       1,                       'A2', '' ],
	[ '100.110p1.less.exact',            'X100',   'X110_P1', 'less',       1, 0,                       1,                       'E2', '' ],
	[ '100.110p1.two.sided.exact',       'X100',   'X110_P1', 'two.sided',  1, 0.21090909090909091,     0.015739183865606153,    'E2', '' ],
	[ 'd1m.d2.greater.asymp',            'D1M',    'D2',     'greater',    0, 0.66666666666666674,     0.34415378686541231,     'A2', '' ],
	[ 'd1m.d2.greater.exact',            'D1M',    'D2',     'greater',    1, 0.66666666666666674,     0.29999999999999999,     'E2', '' ],
	[ 'd1m.d2.less.asymp',               'D1M',    'D2',     'less',       0, 0,                       1,                       'A2', '' ],
	[ 'd1m.d2.less.exact',               'D1M',    'D2',     'less',       1, 0,                       1,                       'E2', '' ],
	[ 'd1m.d2.two.sided.exact',          'D1M',    'D2',     'two.sided',  1, 0.66666666666666674,     0.59999999999999998,     'E2', '' ],
	[ 'd1m.d2f.greater.asymp',           'D1M',    'D2F',    'greater',    0, 0.75,                    0.22313016014842979,     'A2', '' ],
	[ 'd1m.d2f.greater.exact',           'D1M',    'D2F',    'greater',    1, 0.75,                    0.19999999999999998,     'E2', '' ],
	[ 'd1m.d2f.less.asymp',              'D1M',    'D2F',    'less',       0, 0,                       1,                       'A2', '' ],
	[ 'd1m.d2f.less.exact',              'D1M',    'D2F',    'less',       1, 0,                       1,                       'E2', '' ],
	[ 'd1m.d2f.two.sided.exact',         'D1M',    'D2F',    'two.sided',  1, 0.75,                    0.40000000000000002,     'E2', '' ],
	[ 'd1p.d2.greater.asymp',            'D1P',    'D2',     'greater',    0, 0.33333333333333337,     0.76592833836464869,     'A2', '' ],
	[ 'd1p.d2.greater.exact',            'D1P',    'D2',     'greater',    1, 0.33333333333333337,     0.69999999999999996,     'E2', '' ],
	[ 'd1p.d2.less.asymp',               'D1P',    'D2',     'less',       0, 0.33333333333333331,     0.76592833836464869,     'A2', '' ],
	[ 'd1p.d2.less.exact',               'D1P',    'D2',     'less',       1, 0.33333333333333331,     0.69999999999999996,     'E2', '' ],
	[ 'd1p.d2.two.sided.exact',          'D1P',    'D2',     'two.sided',  1, 0.33333333333333337,     1,                       'E2', '' ],
	[ 'd1p.d2f.greater.asymp',           'D1P',    'D2F',    'greater',    0, 0.5,                     0.51341711903259202,     'A2', '' ],
	[ 'd1p.d2f.greater.exact',           'D1P',    'D2F',    'greater',    1, 0.5,                     0.53333333333333333,     'E2', '' ],
	[ 'd1p.d2f.less.asymp',              'D1P',    'D2F',    'less',       0, 0.25,                    0.84648172489061402,     'A2', '' ],
	[ 'd1p.d2f.less.exact',              'D1P',    'D2F',    'less',       1, 0.25,                    0.79999999999999993,     'E2', '' ],
	[ 'd1p.d2f.two.sided.exact',         'D1P',    'D2F',    'two.sided',  1, 0.5,                     0.93333333333333335,     'E2', '' ],
	[ 'eq.m05.greater.asymp',            'D2',     'D2_M05', 'greater',    0, 0,                       1,                       'A2', '' ],
	[ 'eq.m05.greater.exact',            'D2',     'D2_M05', 'greater',    1, 0,                       1,                       'E2', '' ],
	[ 'eq.m05.less.asymp',               'D2',     'D2_M05', 'less',       0, 0.33333333333333331,     0.71653131057378927,     'A2', '' ],
	[ 'eq.m05.less.exact',               'D2',     'D2_M05', 'less',       1, 0.33333333333333331,     0.75,                    'E2', '' ],
	[ 'eq.m05.two.sided.exact',          'D2',     'D2_M05', 'two.sided',  1, 0.33333333333333331,     1,                       'E2', '' ],
	[ 'eq.p05.greater.asymp',            'D2',     'D2_P05', 'greater',    0, 0.33333333333333331,     0.71653131057378927,     'A2', '' ],
	[ 'eq.p05.greater.exact',            'D2',     'D2_P05', 'greater',    1, 0.33333333333333331,     0.75,                    'E2', '' ],
	[ 'eq.p05.less.asymp',               'D2',     'D2_P05', 'less',       0, 0,                       1,                       'A2', '' ],
	[ 'eq.p05.less.exact',               'D2',     'D2_P05', 'less',       1, 0,                       1,                       'E2', '' ],
	[ 'eq.p05.two.sided.exact',          'D2',     'D2_P05', 'two.sided',  1, 0.33333333333333331,     1,                       'E2', '' ],
	[ 'eq.p1.greater.asymp',             'D2',     'D2_P1',  'greater',    0, 0.33333333333333331,     0.71653131057378927,     'A2', '' ],
	[ 'eq.p1.less.asymp',                'D2',     'D2_P1',  'less',       0, 0,                       1,                       'A2', '' ],
	[ 'hw.greater.asymp',                'HW_X',   'HW_Y',   'greater',    0, 0.10000000000000001,     0.90483741803595952,     'A2', '' ],
	[ 'hw.greater.exact',                'HW_X',   'HW_Y',   'greater',    1, 0.10000000000000001,     0.90909090909090906,     'E2', '' ],
	[ 'hw.less.asymp',                   'HW_X',   'HW_Y',   'less',       0, 0.60000000000000009,     0.027323722447292531,    'A2', '' ],
	[ 'hw.less.exact',                   'HW_X',   'HW_Y',   'less',       1, 0.60000000000000009,     0.026223776223776224,    'E2', '' ],
	[ 'hw.two.sided.exact',              'HW_X',   'HW_Y',   'two.sided',  1, 0.60000000000000009,     0.052447552447552434,    'E2', '' ],
	[ 'ks5.greater.asymp',               'KS5_X',  'KS5_Y',  'greater',    0, 0.40000000000000002,     0.63308989218918121,     'A2', '' ],
	[ 'ks5.greater.exact',               'KS5_X',  'KS5_Y',  'greater',    1, 0.40000000000000002,     0.5714285714285714,      'E2', '' ],
	[ 'ks5.less.asymp',                  'KS5_X',  'KS5_Y',  'less',       0, 0.19999999999999996,     0.89200306145309438,     'A2', '' ],
	[ 'ks5.less.exact',                  'KS5_X',  'KS5_Y',  'less',       1, 0.19999999999999996,     0.80952380952380953,     'E2', '' ],
	[ 'ks5.two.sided.exact',             'KS5_X',  'KS5_Y',  'two.sided',  1, 0.40000000000000002,     0.95238095238095244,     'E2', '' ],
	[ 'large.greater.asymp',             'LG_X',   'LG_Y',   'greater',    0, 0.0051000000000000004,   0.99435604663469046,     'A2', '' ],
	# large.less.asymp is deliberately absent: R returns exactly 0 for it out
	# of its own 1 - (1 - exp()) cancellation.  It is asserted further down,
	# under divergence 5.
	[ 'one.01.greater.asymp',            'ONE0',   'ONE1',   'greater',    0, 1,                       0.36787944117144233,     'A2', '' ],
	[ 'one.01.greater.exact',            'ONE0',   'ONE1',   'greater',    1, 1,                       0.5,                     'E2', '' ],
	[ 'one.01.less.asymp',               'ONE0',   'ONE1',   'less',       0, 0,                       1,                       'A2', '' ],
	[ 'one.01.less.exact',               'ONE0',   'ONE1',   'less',       1, 0,                       1,                       'E2', '' ],
	[ 'one.01.two.sided.exact',          'ONE0',   'ONE1',   'two.sided',  1, 1,                       1,                       'E2', '' ],
	[ 'one.10.greater.asymp',            'ONE1',   'ONE0',   'greater',    0, 0,                       1,                       'A2', '' ],
	[ 'one.10.greater.exact',            'ONE1',   'ONE0',   'greater',    1, 0,                       1,                       'E2', '' ],
	[ 'one.10.less.asymp',               'ONE1',   'ONE0',   'less',       0, 1,                       0.36787944117144233,     'A2', '' ],
	[ 'one.10.less.exact',               'ONE1',   'ONE0',   'less',       1, 1,                       0.5,                     'E2', '' ],
	[ 'one.10.two.sided.exact',          'ONE1',   'ONE0',   'two.sided',  1, 1,                       1,                       'E2', '' ],
	[ 'oz.greater.asymp',                'OZ5',    'OZ8',    'greater',    0, 0.53846153846153855,     0.0005322157857965415,   'A2', '' ],
	[ 'oz.less.asymp',                   'OZ5',    'OZ8',    'less',       0, 0,                       1,                       'A2', '' ],
	[ 'qq.greater.asymp',                'QQ_X',   'QQ_Y',   'greater',    0, 0.23999999999999999,     0.056134762834133767,    'A2', '' ],
	[ 'qq.greater.exact',                'QQ_X',   'QQ_Y',   'greater',    1, 0.23999999999999999,     0.056199558169967689,    'E2', '' ],
	[ 'qq.less.asymp',                   'QQ_X',   'QQ_Y',   'less',       0, 0,                       1,                       'A2', '' ],
	[ 'qq.less.exact',                   'QQ_X',   'QQ_Y',   'less',       1, 0,                       1,                       'E2', '' ],
	[ 'qq.two.sided.exact',              'QQ_X',   'QQ_Y',   'two.sided',  1, 0.23999999999999999,     0.11238524845512393,     'E2', '' ],
	[ 'st.greater.asymp',                'ST_X',   'ST_Y',   'greater',    0, 0.42857142857142866,     0.34251885509304547,     'A2', '' ],
	[ 'st.less.asymp',                   'ST_X',   'ST_Y',   'less',       0, 0,                       1,                       'A2', '' ],
	[ 'switzer.greater.asymp',           'SW_F',   'SW_M',   'greater',    0, 0.22500000000000001,     0.13199384318783014,     'A2', '' ],
	[ 'switzer.less.asymp',              'SW_F',   'SW_M',   'less',       0, 0.075000000000000011,    0.79851621875937706,     'A2', '' ],
	[ 'x2233.x3344.greater.asymp',       'X2233',  'X3344',  'greater',    0, 0.3125,                  0.20961138715109784,     'A2', '' ],
	[ 'x2233.x3344.less.asymp',          'X2233',  'X3344',  'less',       0, 0,                       1,                       'A2', '' ],
	[ 'x2356.x3467.greater.asymp',       'X2356',  'X3467',  'greater',    0, 0.34798534798534791,     0.059994729746314368,    'A2', '' ],
	[ 'x2356.x3467.less.asymp',          'X2356',  'X3467',  'less',       0, 0.12820512820512825,     0.68257175908728751,     'A2', '' ],
);

# One-sample against pnorm.  Only two-sided uses R's exact path here; the
# one-sided exact rows are divergences and live in @DIVERGE.  Note that
# norm.inf is TestKSTest.test_pm_inf_gh20386's shape: with -Inf and +Inf both
# in the sample, D and p must still be finite.
my @R_ONE = (
	#  label                            x         y         alternative  ex   D                        p
	[ 'norm.a.greater.asymp',            'SP1_A',  'pnorm',  'greater',    0, 0.15865525393145702,     0.63566294755005637,     'A1', '' ],
	[ 'norm.a.less.asymp',               'SP1_A',  'pnorm',  'less',       0, 0.15865525393145705,     0.63566294755005637,     'A1', '' ],
	[ 'norm.a.two.sided.asymp',          'SP1_A',  'pnorm',  'two.sided',  0, 0.15865525393145705,     0.97727773578380417,     'A1', '' ],
	[ 'norm.a.two.sided.exact',          'SP1_A',  'pnorm',  'two.sided',  1, 0.15865525393145705,     0.95164069201518386,     'E1', '' ],
	[ 'norm.b.greater.asymp',            'SP1_B',  'pnorm',  'greater',    0, 0.44435602715924361,     0.028605936301374157,    'A1', '' ],
	[ 'norm.b.less.asymp',               'SP1_B',  'pnorm',  'less',       0, 0.44435602715924361,     0.028605936301374157,    'A1', '' ],
	[ 'norm.b.two.sided.asymp',          'SP1_B',  'pnorm',  'two.sided',  0, 0.44435602715924361,     0.057210533374330512,    'A1', '' ],
	[ 'norm.b.two.sided.exact',          'SP1_B',  'pnorm',  'two.sided',  1, 0.44435602715924361,     0.038850140086788665,    'E1', '' ],
	[ 'norm.c.greater.asymp',            'SP1_C',  'pnorm',  'greater',    0, 0.29358012680196055,     0.17838951784064153,     'A1', '' ],
	[ 'norm.c.less.asymp',               'SP1_C',  'pnorm',  'less',       0, 0.10934855242569191,     0.78730298421893363,     'A1', '' ],
	[ 'norm.c.two.sided.asymp',          'SP1_C',  'pnorm',  'two.sided',  0, 0.29358012680196055,     0.35476088185936661,     'A1', '' ],
	[ 'norm.c.two.sided.exact',          'SP1_C',  'pnorm',  'two.sided',  1, 0.29358012680196055,     0.29340846368436124,     'E1', '' ],
	[ 'norm.const.two.sided.exact',      'ZERO5',  'pnorm',  'two.sided',  1, 0.5,                     0.11199999999999988,     'E1', '' ],
	[ 'norm.hw.greater.asymp',           'HW_X',   'pnorm',  'greater',    0, 2.7755575615628914e-17,  1,                       'A1', '' ],
	[ 'norm.hw.less.asymp',              'HW_X',   'pnorm',  'less',       0, 0.79343088086445324,     3.4036871631738461e-06,  'A1', '' ],
	# TestKSOneSample.test_known_examples' 100-point fixture, against R.  n =
	# 100 puts the exact row on the far side of the auto-gate, so it exercises
	# K2x at the largest matrix the gate will ever build by itself (m = 2k-1
	# with k = floor(n*D)+1 = 13).
	[ 'norm.kn.two.sided.exact',         'KN',     'pnorm',  'two.sided',  1, 0.12464329735846891,     0.0819733523354228,      'E1', '' ],
	[ 'norm.kn.two.sided.asymp',         'KN',     'pnorm',  'two.sided',  0, 0.12464329735846891,     0.089444888711820825,    'A1', '' ],
	[ 'norm.kn.greater.asymp',           'KN',     'pnorm',  'greater',    0, 0.0072115233216310994,   0.98965269184345384,     'A1', '' ],
	[ 'norm.kn.less.asymp',              'KN',     'pnorm',  'less',       0, 0.12464329735846891,     0.044726446175351056,    'A1', '' ],
	[ 'norm.hw.two.sided.asymp',         'HW_X',   'pnorm',  'two.sided',  0, 0.79343088086445324,     6.8073743263476923e-06,  'A1', '' ],
	[ 'norm.hw.two.sided.exact',         'HW_X',   'pnorm',  'two.sided',  1, 0.79343088086445324,     3.1106659148516513e-07,  'E1', '' ],
	[ 'norm.inf.two.sided.asymp',        'PMINF',  'pnorm',  'two.sided',  0, 0.34134474606854293,     0.73982570174480222,     'A1', '' ],
	[ 'norm.inf.two.sided.exact',        'PMINF',  'pnorm',  'two.sided',  1, 0.34134474606854293,     0.63474755810657446,     'E1', '' ],
	[ 'norm.n1.two.sided.exact',         'ONE0',   'pnorm',  'two.sided',  1, 0.5,                     1,                       'E1', '' ],
);

# Asymptotic two-sided two-sample: pinned against mpmath (mp.dps = 80), which
# sums the defining alternating series
#
#   1 - sum_{k=-inf}^{inf} (-1)^k exp(-2 k^2 z^2),   z = D * sqrt(n1 n2/(n1+n2))
#
# rather than calling any library routine, exactly as CLAUDE.md asks for when
# the XS and a reference disagree.  ks_test() lands within 8.9e-15 of it on
# every row; R is off by up to 4.6e-6 (x2233.x3344, z = 0.884) because
# psmirnov_asymp passes tol = 1e-6 into K2l, and for z < 1 that makes
# k_max = (int)sqrt(2 - log(tol)) = 3, so the k = 3 term of the
# small-argument series -- worth 1.1e-6 at z = 0.866 -- is never added.  R's
# own numbers are in @DIVERGE.
#
# Rows whose D is 0 (two.same) or whose z >= 1 agree with R to 1e-15 anyway;
# they are kept here so the whole path is pinned to one authority.
my @MP_TWO = (
	#  label                            x         y         alternative  ex   D                        p
	[ '100.100m1.two.sided.asymp',       'X100',   'X100_M1', 'two.sided',  0, 0.02,                    1,                       'A2', '' ],
	[ '100.100p1.two.sided.asymp',       'X100',   'X100_P1', 'two.sided',  0, 0.029999999999999999,    0.99999999998534272,     'A2', '' ],
	[ '100.110m1.two.sided.asymp',       'X100',   'X110_M1', 'two.sided',  0, 0.20818181818181825,     0.021339395631001214,    'A2', '' ],
	[ '100.110p1.two.sided.asymp',       'X100',   'X110_P1', 'two.sided',  0, 0.21090909090909091,     0.018931269604367081,    'A2', '' ],
	[ 'd1m.d2.two.sided.asymp',          'D1M',    'D2',     'two.sided',  0, 0.66666666666666674,     0.66038602002996916,     'A2', '' ],
	[ 'd1m.d2f.two.sided.asymp',         'D1M',    'D2F',    'two.sided',  0, 0.75,                    0.44130555778619712,     'A2', '' ],
	[ 'd1p.d2.two.sided.asymp',          'D1P',    'D2',     'two.sided',  0, 0.33333333333333337,     0.99934203846286229,     'A2', '' ],
	[ 'd1p.d2f.two.sided.asymp',         'D1P',    'D2F',    'two.sided',  0, 0.5,                     0.89277833725010858,     'A2', '' ],
	[ 'eq.m05.two.sided.asymp',          'D2',     'D2_M05', 'two.sided',  0, 0.33333333333333331,     0.99625519237939875,     'A2', '' ],
	[ 'eq.p05.two.sided.asymp',          'D2',     'D2_P05', 'two.sided',  0, 0.33333333333333331,     0.99625519237939875,     'A2', '' ],
	[ 'eq.p1.two.sided.asymp',           'D2',     'D2_P1',  'two.sided',  0, 0.33333333333333331,     0.99625519237939875,     'A2', '' ],
	[ 'hw.two.sided.asymp',              'HW_X',   'HW_Y',   'two.sided',  0, 0.60000000000000009,     0.054646330113863502,    'A2', '' ],
	[ 'ks5.two.sided.asymp',             'KS5_X',  'KS5_Y',  'two.sided',  0, 0.40000000000000002,     0.97625891325135938,     'A2', '' ],
	[ 'large.two.sided.asymp',           'LG_X',   'LG_Y',   'two.sided',  0, 0.50249999999999995,     2.7407482181601982e-24,  'A2', '' ],
	[ 'one.01.two.sided.asymp',          'ONE0',   'ONE1',   'two.sided',  0, 1,                       0.69937419913101562,     'A2', '' ],
	[ 'one.10.two.sided.asymp',          'ONE1',   'ONE0',   'two.sided',  0, 1,                       0.69937419913101562,     'A2', '' ],
	[ 'oz.two.sided.asymp',              'OZ5',    'OZ8',    'two.sided',  0, 0.53846153846153855,     0.0010644315714326675,   'A2', '' ],
	[ 'qq.two.sided.asymp',              'QQ_X',   'QQ_Y',   'two.sided',  0, 0.23999999999999999,     0.11224966667072499,     'A2', '' ],
	[ 'st.two.sided.asymp',              'ST_X',   'ST_Y',   'two.sided',  0, 0.42857142857142866,     0.65763983974240825,     'A2', '' ],
	[ 'switzer.two.sided.asymp',         'SW_F',   'SW_M',   'two.sided',  0, 0.22500000000000001,     0.26338063242225734,     'A2', '' ],
	[ 'two.const.two.sided.asymp',       'ZERO5',  'ONE5',   'two.sided',  0, 1,                       0.01347588987586369,     'A2', '' ],
	[ 'two.same.two.sided.asymp',        'ZERO5',  'ZERO5',  'two.sided',  0, 0,                       1,                       'A2', '' ],
	[ 'x2233.x3344.two.sided.asymp',     'X2233',  'X3344',  'two.sided',  0, 0.3125,                  0.41536342829984602,     'A2', '' ],
	[ 'x2356.x3467.two.sided.asymp',     'X2356',  'X3467',  'two.sided',  0, 0.34798534798534791,     0.11996354861856674,     'A2', '' ],
);

# ---------------------------------------------------------------------------
# Corpus 1 runs.

run_row($_, $TOL_P) for @R_TWO;
run_row($_, $TOL_P) for @R_ONE;
run_row($_, $TOL_MP) for @MP_TWO;

# The two cases R's own regression suite pins as fractions rather than
# decimals, restated as fractions so a change in either direction is visible.
# reg-tests-1a.R asserts all.equal(15/286, KSxy$p.value, tol = 1e-15) and
# all.equal(c(D = 0.6), KSxy$statistic, tol = 1e-15); reg-tests-1b.R asserts
# all.equal(20/21, ks5$p.value, tol = 1e-15).
{
	my ($r) = call_ks(\@HW_X, \@HW_Y);
	d_ok($r->{statistic}, 0.6, 'reg-tests-1a: PR#1004 exact D');
	p_ok($r->{p_value}, 15 / 286, 1e-15, 'reg-tests-1a: PR#1004 exact p = 15/286');
	is($r->{method}, $METHOD{E2}, 'reg-tests-1a: auto-gate chose exact');

	my ($k5) = call_ks(\@KS5_X, \@KS5_Y);
	p_ok($k5->{p_value}, 20 / 21, 1e-15, 'reg-tests-1b: ks5 p = 20/21');
}

# ?ks.test's and ?qqplot's printed output, to the digits R prints.  The Ozone
# columns are tied, so only its statistic is reachable; its exact p-value
# (0.0006919 as printed by R) is asserted under divergence 1.
{
	my ($oz) = call_ks(\@OZ5, \@OZ8);
	is(sprintf('%.5f', $oz->{statistic}), '0.53846', 'ks.test.Rd: Ozone D = 0.53846');

	my ($qq) = call_ks(\@QQ_X, \@QQ_Y);
	is(sprintf('%.7f', $qq->{p_value}), '0.1123852', 'qqplot.Rd: p = 0.1123852');
}

# ---------------------------------------------------------------------------
# Corpus 2: SciPy's own hardcoded expectations, reproduced verbatim.
#
# SciPy's ks_2samp with mode='auto' picks exact when max(n1,n2) <= 10000, so
# every row below is called with exact => 1 to hit the same branch.  Only
# tie-free pairs are here: SciPy's exact path ignores ties, so its tied rows
# (testRepeatedValues, and the data2/data2+1 pair of testEqualSizes) contradict
# R and are in @DIVERGE instead.
#
#   label, x, y, alternative, expected D, expected p, tolerance
my @SCIPY_TWO = (
	# TestKSTwoSamples.testSmall
	[ 'scipy testSmall [0] [1] two',  \@ONE0, \@ONE1, 'two.sided', 1.0/1, 1.0, $TOL_SCIPY ],
	[ 'scipy testSmall [0] [1] gt',   \@ONE0, \@ONE1, 'greater',   1.0/1, 0.5, $TOL_SCIPY ],
	[ 'scipy testSmall [0] [1] lt',   \@ONE0, \@ONE1, 'less',      0.0/1, 1.0, $TOL_SCIPY ],
	[ 'scipy testSmall [1] [0] two',  \@ONE1, \@ONE0, 'two.sided', 1.0/1, 1.0, $TOL_SCIPY ],
	[ 'scipy testSmall [1] [0] gt',   \@ONE1, \@ONE0, 'greater',   0.0/1, 1.0, $TOL_SCIPY ],
	[ 'scipy testSmall [1] [0] lt',   \@ONE1, \@ONE0, 'less',      1.0/1, 0.5, $TOL_SCIPY ],
	# TestKSTwoSamples.testTwoVsThree
	[ 'scipy testTwoVsThree d1p two', \@D1P, \@D2, 'two.sided', 1.0/3, 1.0, $TOL_SCIPY ],
	[ 'scipy testTwoVsThree d1p gt',  \@D1P, \@D2, 'greater',   1.0/3, 0.7, $TOL_SCIPY ],
	[ 'scipy testTwoVsThree d1p lt',  \@D1P, \@D2, 'less',      1.0/3, 0.7, $TOL_SCIPY ],
	[ 'scipy testTwoVsThree d1m two', \@D1M, \@D2, 'two.sided', 2.0/3, 0.6, $TOL_SCIPY ],
	[ 'scipy testTwoVsThree d1m gt',  \@D1M, \@D2, 'greater',   2.0/3, 0.3, $TOL_SCIPY ],
	[ 'scipy testTwoVsThree d1m lt',  \@D1M, \@D2, 'less',      0,     1.0, $TOL_SCIPY ],
	# TestKSTwoSamples.testTwoVsFour
	[ 'scipy testTwoVsFour d1p two',  \@D1P, \@D2F, 'two.sided', 2.0/4, 14.0/15, $TOL_SCIPY ],
	[ 'scipy testTwoVsFour d1p gt',   \@D1P, \@D2F, 'greater',   2.0/4,  8.0/15, $TOL_SCIPY ],
	[ 'scipy testTwoVsFour d1p lt',   \@D1P, \@D2F, 'less',      1.0/4, 12.0/15, $TOL_SCIPY ],
	[ 'scipy testTwoVsFour d1m two',  \@D1M, \@D2F, 'two.sided', 3.0/4,  6.0/15, $TOL_SCIPY ],
	[ 'scipy testTwoVsFour d1m gt',   \@D1M, \@D2F, 'greater',   3.0/4,  3.0/15, $TOL_SCIPY ],
	[ 'scipy testTwoVsFour d1m lt',   \@D1M, \@D2F, 'less',      0,      1.0,    $TOL_SCIPY ],
	# TestKSTwoSamples.testEqualSizes, tie-free rows only
	[ 'scipy testEqualSizes +0.5 two', \@D2, \@D2_P05, 'two.sided', 1.0/3, 1.0,  $TOL_SCIPY ],
	[ 'scipy testEqualSizes +0.5 gt',  \@D2, \@D2_P05, 'greater',   1.0/3, 0.75, $TOL_SCIPY ],
	[ 'scipy testEqualSizes +0.5 lt',  \@D2, \@D2_P05, 'less',      0.0/3, 1.0,  $TOL_SCIPY ],
	[ 'scipy testEqualSizes -0.5 two', \@D2, \@D2_M05, 'two.sided', 1.0/3, 1.0,  $TOL_SCIPY ],
	[ 'scipy testEqualSizes -0.5 gt',  \@D2, \@D2_M05, 'greater',   0.0/3, 1.0,  $TOL_SCIPY ],
	[ 'scipy testEqualSizes -0.5 lt',  \@D2, \@D2_M05, 'less',      1.0/3, 0.75, $TOL_SCIPY ],
	# TestKSTwoSamples.test100_100
	[ 'scipy test100_100 +0.1 two', \@X100, \@X100_P1, 'two.sided', 3.0/100, 0.9999999999962055, $TOL_SCIPY ],
	[ 'scipy test100_100 +0.1 gt',  \@X100, \@X100_P1, 'greater',   3.0/100, 0.9143290114276248, $TOL_SCIPY ],
	[ 'scipy test100_100 +0.1 lt',  \@X100, \@X100_P1, 'less',      0,       1.0,                $TOL_SCIPY ],
	[ 'scipy test100_100 -0.1 two', \@X100, \@X100_M1, 'two.sided', 2.0/100, 1.0,                $TOL_SCIPY ],
	[ 'scipy test100_100 -0.1 gt',  \@X100, \@X100_M1, 'greater',   2.0/100, 0.960978450786184,  $TOL_SCIPY ],
	[ 'scipy test100_100 -0.1 lt',  \@X100, \@X100_M1, 'less',      0,       1.0,                $TOL_SCIPY ],
	# TestKSTwoSamples.test100_110
	[ 'scipy test100_110 +0.1 two', \@X100, \@X110_P1, 'two.sided', 232.0/1100, 0.015739183865607353,  $TOL_SCIPY ],
	[ 'scipy test100_110 +0.1 gt',  \@X100, \@X110_P1, 'greater',   232.0/1100, 0.007869594319053203,  $TOL_SCIPY ],
	[ 'scipy test100_110 +0.1 lt',  \@X100, \@X110_P1, 'less',      0,          1,                     $TOL_SCIPY ],
	[ 'scipy test100_110 -0.1 two', \@X100, \@X110_M1, 'two.sided', 229.0/1100, 0.017803803861026313,  $TOL_SCIPY ],
	[ 'scipy test100_110 -0.1 gt',  \@X100, \@X110_M1, 'greater',   229.0/1100, 0.008901905958245056,  $TOL_SCIPY ],
	[ 'scipy test100_110 -0.1 lt',  \@X100, \@X110_M1, 'less',      0.0,        1.0,                   $TOL_SCIPY ],
	# TestKSTwoSamples.testLarge, one-sided rows (10000 x 110; lcm = 110000).
	# ks_test()'s auto-gate would go asymptotic here (n1*n2 = 1.1e6), so exact
	# has to be forced -- 1.1e6 is still well under KS_EXACT_MAX_PRODUCT.
	[ 'scipy testLarge gt', \@LG_X, \@LG_Y, 'greater', 561.0/110000,   0.99115454582047591,    $TOL_SCIPY_BIG ],
	[ 'scipy testLarge lt', \@LG_X, \@LG_Y, 'less',    55275.0/110000, 3.1317328311518713e-26, $TOL_SCIPY_BIG ],
);

for my $row (@SCIPY_TWO) {
	my ($label, $x, $y, $alt, $d_want, $p_want, $tol) = @$row;
	my ($r, $warns) = call_ks($x, $y, alternative => $alt, exact => 1);
	d_ok($r->{statistic}, $d_want, $label);
	p_ok($r->{p_value}, $p_want, $tol, $label);
	is(scalar(@$warns), 0, "$label: no warnings") or diag("warnings: @$warns");
}

# TestKSOneSample.test_agree_with_r and .test_known_examples.  SciPy's
# ks_1samp calls special.ndtr as the CDF, which is ks_test()'s 'pnorm'.  Only
# the two-sided rows are comparable: SciPy ignores `mode` for one-sided
# alternatives (see @DIVERGE).
#
#   label, x, exact argument, expected D, expected p
my @SCIPY_ONE = (
	[ 'scipy test_agree_with_r linspace(-1,1,9)',   \@SP1_A, 1, 0.15865525393145705, 0.95164069201518386 ],
	[ 'scipy test_agree_with_r linspace(-15,15,9)', \@SP1_B, 1, 0.44435602715924361, 0.038850140086788665 ],
	[ 'scipy test_agree_with_r 10-value sample',    \@SP1_C, 1, 0.293580126801961,   0.293408463684361 ],
	# mode='asymp'; n = 100, so ks_test()'s auto-gate would also go asymptotic.
	[ 'scipy test_known_examples asymp',            \@KN,    0, 0.12464329735846891, 0.089444888711820769 ],
);

for my $row (@SCIPY_ONE) {
	my ($label, $x, $exact, $d_want, $p_want) = @$row;
	my ($r, $warns) = call_ks($x, 'pnorm', alternative => 'two.sided', exact => $exact);
	d_ok($r->{statistic}, $d_want, $label);
	# exact => 1 is the 1 - K2x() cancellation path; see $TOL_P_ABS.  None of
	# these three actually need the floor on a double build (worst is 6.5e-15
	# relative), but a wider NV drifts from SciPy absolutely, not relatively.
	p_ok($r->{p_value}, $p_want, $TOL_SCIPY, $label,
		$exact ? $TOL_P_ABS : 0);
	is(scalar(@$warns), 0, "$label: no warnings") or diag("warnings: @$warns");
}

# ---------------------------------------------------------------------------
# The exact/asymptotic auto-gate.  R's rule is exact <- (n.x * n.y < 10000)
# for two samples and (n < 100) && !TIES for one, and ks_test() must land on
# the same side of both boundaries, so both are probed at n and n-1.
{
	my @a   = map { $_ * 1.0 } 1 .. 100;
	my @b   = map { $_ + 0.5 } 1 .. 100;   # 100 * 100 = 10000, not < 10000
	my @b99 = map { $_ + 0.5 } 1 .. 99;    # 100 *  99 =  9900,     < 10000
	my ($hi) = call_ks(\@a, \@b);
	my ($lo) = call_ks(\@a, \@b99);
	is($hi->{method}, $METHOD{A2}, 'auto-gate: n.x*n.y = 10000 is asymptotic');
	is($lo->{method}, $METHOD{E2}, 'auto-gate: n.x*n.y =  9900 is exact');
	p_ok($hi->{p_value}, 1, $TOL_P, 'auto-gate 10000');   # R: 1
	p_ok($lo->{p_value}, 1, $TOL_P, 'auto-gate 9900');    # R: 1

	# One-sample: R's auto-exact values for these two, generated alongside the
	# corpus.  The statistic is the same; only the p-value path changes.
	my @n99  = map { $_ / 100 } 1 .. 99;
	my @n100 = map { $_ / 100 } 1 .. 100;
	my ($e1) = call_ks(\@n99,  'pnorm');
	my ($a1) = call_ks(\@n100, 'pnorm');
	is($e1->{method}, $METHOD{E1}, 'auto-gate: n = 99 is exact');
	is($a1->{method}, $METHOD{A1}, 'auto-gate: n = 100 is asymptotic');
	d_ok($e1->{statistic}, 0.5039893563146316, 'auto-gate n=99');
	d_ok($a1->{statistic}, 0.5039893563146316, 'auto-gate n=100');
	# n=99 goes through 1 - K2x(), where the true upper tail is 8.35e-24 while
	# R and a double-NV ks_test both report 2.0e-15 and a long-double or
	# quadmath ks_test reports exactly 0: the cancellation has eaten every
	# significant digit, and how much of the noise survives depends on the NV
	# width.  Asserted against R's value on the absolute floor, and separately
	# bounded, because a *relative* assertion here would be a lie.  See
	# $TOL_P_ABS.
	p_ok($e1->{p_value}, 1.9984014443252818e-15, $TOL_P, 'auto-gate n=99',
		$TOL_P_ABS);
	cmp_ok($e1->{p_value}, '<', 1e-13,
		'auto-gate n=99: 1 - K2x() is only absolutely accurate, but still tiny');
	# n=100 uses K2l()'s direct upper-tail series, so this one really is
	# relatively accurate.
	p_ok($a1->{p_value}, 1.7314599783659416e-22, $TOL_P, 'auto-gate n=100');

	# exact => undef is documented to mean "auto", i.e. the same as omitting it.
	my ($u) = call_ks(\@a, \@b99, exact => undef);
	is($u->{method}, $METHOD{E2}, 'exact => undef means auto');
	p_ok($u->{p_value}, $lo->{p_value}, 0, 'exact => undef matches auto exactly');
}

# A forced exact run past KS_EXACT_MAX_PRODUCT (1e7) must warn and degrade to
# asymptotic rather than allocate and grind.  3200 * 3200 = 1.024e7.
{
	my @b1 = map { $_ * 1.0 } 1 .. 3200;
	my @b2 = map { $_ + 0.5 } 1 .. 3200;
	my ($r, $warns) = call_ks(\@b1, \@b2, exact => 1);
	is($r->{method}, $METHOD{A2}, 'forced exact past 1e7 falls back to asymptotic');
	is(scalar(grep { $_ =~ $WARN_RE{big} } @$warns), 1,
		'forced exact past 1e7 warns');
	# R (which has no such cap): D = 1/3200 exactly.
	d_ok($r->{statistic}, 1 / 3200, 'forced exact past 1e7');
}

# ---------------------------------------------------------------------------
# Missing and non-finite values.
#
# R drops them up front (x <- x[!is.na(x)]), which for NaN as well as NA means
# the test runs on the remaining observations.  ks_test() must agree, and for
# the two-sample case it *must*: the merge in calc_2sample_stats() advances
# only on `<=`, so a NaN that reached it would never be consumed and the loop
# would never terminate.  These cases are the regression guard for that.
{
	my $NAN = $INF - $INF;
	ok($NAN != $NAN, 'sanity: $NAN is a NaN');

	# R: ks.test(c(1,2,3), c(5,6,7,8)) -> D = 1, p = 0.057142857142857141
	my ($r) = call_ks([1, 2, $NAN, 3], [5, 6, 7, 8]);
	d_ok($r->{statistic}, 1, 'NaN dropped from x (two-sample)');
	p_ok($r->{p_value}, 0.057142857142857141, $TOL_P, 'NaN dropped from x (two-sample)');

	my ($r2) = call_ks([1, 2, 3], [5, $NAN, 6, 7, 8]);
	d_ok($r2->{statistic}, 1, 'NaN dropped from y (two-sample)');
	p_ok($r2->{p_value}, 0.057142857142857141, $TOL_P, 'NaN dropped from y (two-sample)');

	# R: ks.test(c(1,2,3), "pnorm") -> D = 0.84134474606854293,
	#                                  p = 0.0079871781486594573
	my ($r3) = call_ks([1, 2, $NAN, 3], 'pnorm');
	d_ok($r3->{statistic}, 0.84134474606854293, 'NaN dropped from x (one-sample)');
	p_ok($r3->{p_value}, 0.0079871781486594573, $TOL_P, 'NaN dropped from x (one-sample)');

	# undef and non-numeric strings are dropped the same way; this is the same
	# 3-vs-4 comparison as above, reached from a 5-element x.
	my ($r4) = call_ks([1, undef, 2, 'not a number', 3], [5, 6, 7, 8]);
	d_ok($r4->{statistic}, 1, 'undef and non-numeric dropped');
	p_ok($r4->{p_value}, 0.057142857142857141, $TOL_P, 'undef and non-numeric dropped');

	# Strings that *do* look like numbers are kept, and take the
	# looks_like_number() branch rather than the SvNIOK shortcut.  Same
	# 4-vs-4 comparison as ks_test([1,2,3,4],[5,6,7,8]) in R.
	my ($r5) = call_ks(['1', ' 2 ', '3e0', '4.0'], ['5', '6', '7', '8']);
	d_ok($r5->{statistic}, 1, 'numeric strings are parsed, not dropped');
	p_ok($r5->{p_value}, 0.028571428571428571, $TOL_P,
		'numeric strings are parsed, not dropped');

	# R also warns "p-value will be approximate in the presence of ties" when
	# ties meet the *asymptotic* path; ks_test does not, on the grounds that
	# nothing was fallen back from.  Pinned so the silence is deliberate.
	my (undef, $tie_warns) = call_ks(\@ST_X, \@ST_Y, exact => 0);
	is(scalar(@$tie_warns), 0,
		'ties on the asymptotic path are silent (R warns here, ks_test does not)')
		or diag("warnings: @$tie_warns");
}

# ---------------------------------------------------------------------------
# The accepted call forms all reach the same code.  R's ks.test(x, y) is
# positional; ks_test() also takes x/y by name, and mixes the two.
{
	my @x = (1, 2, 3, 4);
	my @y = (5, 6, 7, 8);
	my ($pos) = call_ks(\@x, \@y);
	is_deeply(ks_test(x => \@x, y => \@y), $pos,
		'call form: named x and y agrees with positional');
	is_deeply(ks_test(\@x, y => \@y), $pos,
		'call form: positional x with named y agrees with positional');
	is_deeply(ks_test(\@x, \@y, alternative => 'two.sided'), $pos,
		'call form: explicit default alternative agrees with positional');
	# R: ks.test(c(1,2,3,4), c(5,6,7,8)) -> D = 1, p = 0.028571428571428571
	d_ok($pos->{statistic}, 1, 'fully separated 4 vs 4');
	p_ok($pos->{p_value}, 0.028571428571428571, $TOL_P, 'fully separated 4 vs 4');

	# One-sample, both ways.
	my ($p1) = call_ks([-1, 0, 1], 'pnorm');
	is_deeply(ks_test(x => [-1, 0, 1], y => 'pnorm'), $p1,
		'call form: named y => pnorm agrees with positional');
	# R: ks.test(c(-1,0,1), "pnorm") -> D = 0.1746780794018763, p = 0.99997531867011236
	d_ok($p1->{statistic}, 0.1746780794018763, 'one-sample pnorm');
	p_ok($p1->{p_value}, 0.99997531867011236, $TOL_P, 'one-sample pnorm');

	# The trailing-string heuristic: a bare 'pnorm' is only taken as y when
	# doing so leaves an even number of named arguments behind it, so
	# ks_test(\@x, 'pnorm', exact => 0) is one-sample, not a parse error.
	my ($p2) = call_ks([-1, 0, 1], 'pnorm', exact => 0);
	is($p2->{method}, $METHOD{A1}, 'one-sample with exact => 0 parses');
	p_ok($p2->{p_value}, 0.99998838403246959, $TOL_P, 'one-sample asymptotic pnorm');

	# All four return keys are present and nothing else is.
	is_deeply([sort keys %$pos], [qw(alternative method p_value statistic)],
		'return hash has exactly the four documented keys');
}

# ---------------------------------------------------------------------------
# Argument validation.  Every croak path ks_test() has.
{
	my @x = (1, 2, 3, 4);
	my @y = (5, 6, 7, 8);
	my $NAN = $INF - $INF;
	my @croaks = (
		[ 'no arguments at all', sub { ks_test() },
		  qr/^ks_test: 'x' is a required argument and must be an ARRAY reference/ ],
		[ 'x is not a reference', sub { ks_test(x => 5, y => \@y) },
		  qr/^ks_test: 'x' is a required argument and must be an ARRAY reference/ ],
		[ 'unknown alternative', sub { ks_test(\@x, \@y, alternative => 'up') },
		  qr/^ks_test: alternative must be 'two\.sided', 'less', or 'greater'/ ],
		# R accepts match.arg abbreviations ('gr', 'l'); ks_test does not, and
		# says so rather than silently defaulting to two-sided.
		[ 'abbreviated alternative', sub { ks_test(\@x, \@y, alternative => 'gr') },
		  qr/^ks_test: alternative must be 'two\.sided', 'less', or 'greater'/ ],
		[ 'unknown named argument', sub { ks_test(\@x, \@y, mode => 'exact') },
		  qr/^ks_test: unknown argument 'mode'/ ],
		[ 'named argument with no value', sub { ks_test(\@x, \@y, 'exact') },
		  qr/^ks_test: argument 'exact' is missing a value/ ],
		[ 'unsupported 1-sample distribution', sub { ks_test(\@x, 'punif') },
		  qr/^ks_test: Unsupported 1-sample distribution 'punif'\. Use arrays for 2-sample\./ ],
		[ 'y neither array ref nor CDF name', sub { ks_test(\@x, exact => 1) },
		  qr/^ks_test: Invalid arguments for 'y'\./ ],
		[ 'empty x', sub { ks_test([], \@y) },
		  qr/^Not enough 'x' observations/ ],
		[ 'x is all missing', sub { ks_test([undef, undef], \@y) },
		  qr/^Not enough non-missing 'x' observations/ ],
		[ 'empty y', sub { ks_test(\@x, []) },
		  qr/^Not enough non-missing observations for KS test/ ],
		[ 'y is all missing', sub { ks_test(\@x, [undef, undef]) },
		  qr/^Not enough non-missing observations for KS test/ ],
		[ 'x is all NaN', sub { ks_test([$NAN, $NAN], \@y) },
		  qr/^Not enough non-missing 'x' observations/ ],
		[ 'y is all NaN', sub { ks_test(\@x, [$NAN, $NAN]) },
		  qr/^Not enough non-missing observations for KS test/ ],
	);
	for my $c (@croaks) {
		my ($label, $code, $re) = @$c;
		my $ok = eval { $code->(); 1 };
		my $err = $ok ? '' : "$@";
		ok(!$ok, "croak: $label dies") or next;
		like($err, $re, "croak: $label message");
	}

	# A hash ref where y belongs is neither an array ref nor a string, so it
	# falls through to the named-argument loop and is reported as a stray key.
	# The message stringifies the ref, so match loosely.
	my $ok = eval { ks_test(\@x, {}); 1 };
	ok(!$ok, 'croak: hashref y dies');
	like("$@", qr/^ks_test: argument 'HASH\(0x[0-9a-f]+\)' is missing a value/,
		'croak: hashref y message');
}

# ---------------------------------------------------------------------------
# No SV leaks over the exact and asymptotic branches of both sample counts,
# plus a warning path and a croak path.
SKIP: {
	skip 'Test::LeakTrace not installed', 1 unless $HAVE_LEAKTRACE;
	no_leaks_ok {
		my @warns;
		local $SIG{__WARN__} = sub { push @warns, $_[0] };
		ks_test(\@HW_X, \@HW_Y);
		ks_test(\@HW_X, \@HW_Y, exact => 0);
		ks_test(\@HW_X, \@HW_Y, alternative => 'greater');
		ks_test(\@ST_X, \@ST_Y, exact => 1);            # ties -> warn + fallback
		ks_test(\@HW_X, 'pnorm');
		ks_test(\@HW_X, 'pnorm', exact => 0);
		ks_test(\@HW_X, 'pnorm', alternative => 'less', exact => 1);
		eval { ks_test(\@HW_X, 'punif') };
		eval { ks_test([], \@HW_Y) };
		eval { ks_test([undef], \@HW_Y) };
		eval { ks_test(\@HW_X, [undef]) };
		eval { ks_test(\@HW_X, \@HW_Y, alternative => 'sideways') };
	} 'no SV leaks across every branch, including warns and croaks';
}

# ---------------------------------------------------------------------------
# Recorded divergences.
#
# Each row asserts BOTH sides: that ks_test() still produces what it produces
# now, and that the reference still produces something different.  A change to
# either therefore has to be made here on purpose.  Columns are
#
#   label, x fixture, y fixture, alternative, exact argument, expected D,
#   what ks_test() gives, what the reference gives (undef if the reference
#   returns NaN), which gap this is, and the reference's name.
#
# 'ties' rows: R 4.6's psmirnov() conditions the lattice DP on the observed tie
# pattern, which is a strictly different (and correct) null distribution;
# ks_test() warns and returns the asymptotic value instead.  The
# ks_test()-side numbers for two-sided rows are mpmath's (see @MP_TWO), since
# that is the path the fallback lands on.
#
# 'one1' rows: R uses pkolmogorov_one_exact, the Birnbaum & Tingey (1951)
# series; ks_test() warns and returns exp(-2*n*D^2).  Note norm.hw.greater,
# where R itself returns NaN: with D = 2.8e-17 the series evaluates
# (j-1)*log(q + j/n) at j = 0, i.e. -log(q) times -1, and the j = 0 term
# overwhelms the rest.  ks_test() returns 1, which is the right answer for a
# statistic of 0.
my @DIVERGE = (
	[ 'eq.p1.greater.exact',             'D2',     'D2_P1',  'greater',    1, 0.33333333333333331,     0.71653131057378927,     0.75,                    'ties',  'R exact (tie-conditional)' ],
	[ 'eq.p1.less.exact',                'D2',     'D2_P1',  'less',       1, 0,                       1,                       1,                       'ties',  'R exact (tie-conditional)' ],
	[ 'eq.p1.two.sided.exact',           'D2',     'D2_P1',  'two.sided',  1, 0.33333333333333331,     0.99625519237939875,     1,                       'ties',  'R exact (tie-conditional)' ],
	[ 'norm.a.greater.exact',            'SP1_A',  'pnorm',  'greater',    1, 0.15865525393145702,     0.63566294755005659,     0.57863894131082805,     'one1',  'R exact (Birnbaum-Tingey)' ],
	[ 'norm.a.less.exact',               'SP1_A',  'pnorm',  'less',       1, 0.15865525393145705,     0.63566294755005637,     0.57863894131082749,     'one1',  'R exact (Birnbaum-Tingey)' ],
	[ 'norm.b.greater.exact',            'SP1_B',  'pnorm',  'greater',    1, 0.44435602715924361,     0.028605936301374171,    0.019425071352585584,    'one1',  'R exact (Birnbaum-Tingey)' ],
	[ 'norm.b.less.exact',               'SP1_B',  'pnorm',  'less',       1, 0.44435602715924361,     0.028605936301374171,    0.019425071352585584,    'one1',  'R exact (Birnbaum-Tingey)' ],
	[ 'norm.c.greater.exact',            'SP1_C',  'pnorm',  'greater',    1, 0.29358012680196055,     0.17838951784064153,     0.14698883504237564,     'one1',  'R exact (Birnbaum-Tingey)' ],
	[ 'norm.c.less.exact',               'SP1_C',  'pnorm',  'less',       1, 0.10934855242569191,     0.78730298421893363,     0.73276889247067534,     'one1',  'R exact (Birnbaum-Tingey)' ],
	[ 'norm.hw.greater.exact',           'HW_X',   'pnorm',  'greater',    1, 2.7755575615628914e-17,  1,                       undef,                   'one1',  'R exact (Birnbaum-Tingey)' ],
	[ 'norm.hw.less.exact',              'HW_X',   'pnorm',  'less',       1, 0.79343088086445324,     3.4036871631738461e-06,  1.5553329561954807e-07,  'one1',  'R exact (Birnbaum-Tingey)' ],
	# SciPy's ks_1samp ignores mode entirely for one-sided alternatives and
	# always returns the exact ksone survival function, so its own
	# test_known_examples expectations for these two -- 0.98531158590396228
	# (greater) and 0.040989164077641749 (less) -- are R's exact values, not
	# its asymptotic ones.  R agrees with SciPy to 1.3e-16 on both.
	[ 'norm.kn.greater.exact',           'KN',     'pnorm',  'greater',    1, 0.0072115233216310994,   0.98965269184345384,     0.98531158590396206,     'one1',  'R and SciPy exact (Birnbaum-Tingey / ksone)' ],
	[ 'norm.kn.less.exact',              'KN',     'pnorm',  'less',       1, 0.12464329735846891,     0.044726446175351056,    0.040989164077641756,    'one1',  'R and SciPy exact (Birnbaum-Tingey / ksone)' ],
	[ 'oz.greater.exact',                'OZ5',    'OZ8',    'greater',    1, 0.53846153846153855,     0.00053221578579656687,  0.00034594252434190243,  'ties',  'R exact (tie-conditional)' ],
	[ 'oz.less.exact',                   'OZ5',    'OZ8',    'less',       1, 0,                       1,                       1,                       'ties',  'R exact (tie-conditional)' ],
	[ 'oz.two.sided.exact',              'OZ5',    'OZ8',    'two.sided',  1, 0.53846153846153855,     0.0010644315714326675,   0.00069188504868380476,  'ties',  'R exact (tie-conditional)' ],
	[ 'st.greater.exact',                'ST_X',   'ST_Y',   'greater',    1, 0.42857142857142866,     0.34251885509304564,     0.17803030303030307,     'ties',  'R exact (tie-conditional)' ],
	[ 'st.less.exact',                   'ST_X',   'ST_Y',   'less',       1, 0,                       1,                       1,                       'ties',  'R exact (tie-conditional)' ],
	[ 'st.two.sided.exact',              'ST_X',   'ST_Y',   'two.sided',  1, 0.42857142857142866,     0.65763983974240825,     0.24242424242424243,     'ties',  'R exact (tie-conditional)' ],
	[ 'switzer.greater.exact',           'SW_F',   'SW_M',   'greater',    1, 0.22500000000000001,     0.13199384318783022,     0.10610007481926112,     'ties',  'R exact (tie-conditional)' ],
	[ 'switzer.less.exact',              'SW_F',   'SW_M',   'less',       1, 0.075000000000000011,    0.79851621875937717,     0.76385045888189063,     'ties',  'R exact (tie-conditional)' ],
	[ 'switzer.two.sided.exact',         'SW_F',   'SW_M',   'two.sided',  1, 0.22500000000000001,     0.26338063242225734,     0.21198990394624936,     'ties',  'R exact (tie-conditional)' ],
	[ 'two.const.two.sided.exact',       'ZERO5',  'ONE5',   'two.sided',  1, 1,                       0.01347588987586369,     0.0079365079365079361,   'ties',  'R exact (tie-conditional)' ],
	[ 'two.same.two.sided.exact',        'ZERO5',  'ZERO5',  'two.sided',  1, 0,                       1,                       1,                       'ties',  'R exact (tie-conditional)' ],
	[ 'x2233.x3344.greater.exact',       'X2233',  'X3344',  'greater',    1, 0.3125,                  0.20961138715109778,     0.099104941686751741,    'ties',  'R exact (tie-conditional)' ],
	[ 'x2233.x3344.less.exact',          'X2233',  'X3344',  'less',       1, 0,                       1,                       1,                       'ties',  'R exact (tie-conditional)' ],
	[ 'x2233.x3344.two.sided.exact',     'X2233',  'X3344',  'two.sided',  1, 0.3125,                  0.41536342829984602,     0.19820988337350354,     'ties',  'R exact (tie-conditional)' ],
	[ 'x2356.x3467.greater.exact',       'X2356',  'X3467',  'greater',    1, 0.34798534798534791,     0.059994729746314313,    0.023493029705930257,    'ties',  'R exact (tie-conditional)' ],
	[ 'x2356.x3467.less.exact',          'X2356',  'X3467',  'less',       1, 0.12820512820512825,     0.68257175908728751,     0.38140754084210976,     'ties',  'R exact (tie-conditional)' ],
	[ 'x2356.x3467.two.sided.exact',     'X2356',  'X3467',  'two.sided',  1, 0.34798534798534791,     0.11996354861856674,     0.035217727116839348,    'ties',  'R exact (tie-conditional)' ],
);

for my $row (@DIVERGE) {
	my ($label, $xn, $yn, $alt, $exact, $d_want, $p_ours, $p_ref, $tag, $ref) = @$row;
	my $x = $DATA{$xn} or die "no such fixture '$xn'";
	my $y = $yn eq 'pnorm' ? 'pnorm' : ($DATA{$yn} or die "no such fixture '$yn'");
	my ($r, $warns) = call_ks($x, $y, alternative => $alt, exact => $exact);

	d_ok($r->{statistic}, $d_want, "diverge $label");
	p_ok($r->{p_value}, $p_ours, $TOL_P, "diverge $label (ks_test's own value)");

	# The warning is the contract: it is how a caller learns the p-value is
	# not the exact one it asked for.
	is(scalar(grep { $_ =~ $WARN_RE{$tag} } @$warns), 1,
		"diverge $label: warns ($tag)") or diag("warnings: @$warns");

	# ...and the fallback really is the asymptotic method, not a mislabelled
	# exact one.
	is($r->{method}, $yn eq 'pnorm' ? $METHOD{A1} : $METHOD{A2},
		"diverge $label: method says asymptotic");

	# Assert the divergence itself against the live value, so that closing the
	# gap fails here loudly rather than passing silently.  A handful of rows
	# agree with the reference anyway -- the D = 0 ones, where every
	# distribution gives p = 1 -- and those are asserted as agreeing.
	if (!defined $p_ref) {
		# R returned NaN; there is nothing to compare to, only to record.
		ok($r->{p_value} == $r->{p_value},
			"diverge $label: $ref returns NaN, ks_test returns a number");
	}
	elsif (abs($p_ref - $p_ours) <= $TOL_P * abs($p_ref)) {
		p_ok($r->{p_value}, $p_ref, $TOL_P,
			"diverge $label: agrees with $ref at this D anyway");
	}
	else {
		ok(abs($r->{p_value} - $p_ref) > $TOL_P * abs($p_ref),
			sprintf('diverge %s: still differs from %s (%.17g vs %.17g)',
				$label, $ref, $r->{p_value}, $p_ref));
	}
}

# One-sample auto-gate with ties (divergence 3).  R's rule is
# (n < 100) && !TIES, so a tied one-sample input goes asymptotic there;
# ks_test() only tests n < 100 and stays exact.  ks_test()'s value is exactly
# R's exact=TRUE value, so the disagreement is entirely in which branch the
# gate picks, not in the arithmetic.
{
	my @tied = (1, 1, 2, 2, 3, 3);
	my ($auto)  = call_ks(\@tied, 'pnorm');
	my ($forced) = call_ks(\@tied, 'pnorm', exact => 1);
	my ($asymp)  = call_ks(\@tied, 'pnorm', exact => 0);

	is($auto->{method}, $METHOD{E1},
		'diverge 1-sample tied auto-gate: ks_test stays exact where R goes asymptotic');
	d_ok($auto->{statistic}, 0.84134474606854293, 'diverge 1-sample tied auto-gate');
	# R: ks.test(c(1,1,2,2,3,3), "pnorm", exact = TRUE)  -> 3.1897507389189172e-05
	# Another 1 - K2x() value, so it carries the absolute floor: K2x returns
	# 0.999968 here and the subtraction leaves only ~11 significant digits, a
	# 3e-12 relative error that a wider NV build would not make.
	p_ok($auto->{p_value}, 3.1897507389189172e-05, $TOL_P,
		'diverge 1-sample tied auto-gate: matches R exact=TRUE', $TOL_P_ABS);
	p_ok($forced->{p_value}, $auto->{p_value}, 0,
		'diverge 1-sample tied auto-gate: auto == forced exact');
	# R: ks.test(c(1,1,2,2,3,3), "pnorm")               -> 0.00040924989417562329
	# which is R's exact=FALSE value, i.e. what ks_test() gives only on request.
	p_ok($asymp->{p_value}, 0.00040924989417562329, $TOL_P,
		"diverge 1-sample tied auto-gate: R's auto value is ks_test's exact => 0");
	isnt(sprintf('%.17g', $auto->{p_value}), sprintf('%.17g', $asymp->{p_value}),
		'diverge 1-sample tied auto-gate: the two branches really differ');
}

# R's asymptotic one-sided upper tail underflows to exactly 0 (divergence 5).
# psmirnov_asymp computes ret <- -expm1(-2*n*q^2) and then returns 1 - ret, so
# once exp(-2*n*q^2) drops below the double epsilon the value is lost.  Here
# 2*n*q^2 = 54.94 with n = n1*n2/(n1+n2) = 108.8 and q = 0.5025, so R reports
# 0 where the quantity is 1.37e-24.  ks_test() evaluates exp() directly.
{
	my ($r) = call_ks(\@LG_X, \@LG_Y, alternative => 'less', exact => 0);
	d_ok($r->{statistic}, 0.50249999999999995, 'diverge R one-sided underflow');
	# mpmath at mp.dps = 80: exp(-2*n*q^2) = 1.3703741090800991e-24.  ks_test lands
	# 9e-15 relative away, which is nv_exp() at an argument of -54.9, not the
	# formula.
	p_ok($r->{p_value}, 1.3703741090800991e-24, 1e-13,
		'diverge R one-sided underflow: ks_test keeps the value');
	cmp_ok($r->{p_value}, '>', 0,
		'diverge R one-sided underflow: R returns exactly 0 here, ks_test does not');
}

# SciPy's exact two-sided p-value floors near its own epsilon (divergence 7).
# TestKSTwoSamples.testLarge expects 4.2188474935755949e-15 for the 10000x110
# two-sided case, and test_gh11184_bigger annotates the same saturation for
# 10000x10001 ("2.7755575615628914e-15" = 12.5 * DBL_EPSILON).  R's lattice DP
# gives 6.2634656622608498e-26 for this case, and ks_test() reproduces R to
# 1e-15, so the reference that is wrong here is SciPy's.
{
	my ($r) = call_ks(\@LG_X, \@LG_Y, alternative => 'two.sided', exact => 1);
	d_ok($r->{statistic}, 55275.0 / 110000, 'diverge SciPy exact two-sided floor');
	p_ok($r->{p_value}, 6.2634656622608498e-26, $TOL_P,
		'diverge SciPy exact two-sided floor: ks_test matches R');
	cmp_ok($r->{p_value}, '<', 1e-20,
		'diverge SciPy exact two-sided floor: SciPy stops at 4.2e-15');
}

# SciPy's tied exact rows (divergence 7, second half).  TestKSTwoSamples
# .testRepeatedValues and the data2/data2+1 pair of .testEqualSizes are
# reproduced here with SciPy's own expectations, purely to record that SciPy,
# R and ks_test() give three different answers on the same input: SciPy runs
# the no-tie formula, R conditions on the ties, ks_test() warns and goes
# asymptotic.  The statistic, which nobody disagrees about, is still asserted.
#
#   label, x, y, alternative, SciPy's D, SciPy's p, R's exact p
my @SCIPY_TIED = (
	[ 'scipy testRepeatedValues x2233 two', \@X2233, \@X3344, 'two.sided',
	  5.0/16, 0.4262934613454952,  0.19820988337350354 ],
	[ 'scipy testRepeatedValues x2233 gt',  \@X2233, \@X3344, 'greater',
	  5.0/16, 0.21465428276573786, 0.099104941686751741 ],
	[ 'scipy testRepeatedValues x2233 lt',  \@X2233, \@X3344, 'less',
	  0.0/16, 1.0,                 1.0 ],
	[ 'scipy testRepeatedValues x2356 two', \@X2356, \@X3467, 'two.sided',
	  190.0/21/26, 0.0919245790168125,  0.035217727116839348 ],
	[ 'scipy testRepeatedValues x2356 gt',  \@X2356, \@X3467, 'greater',
	  190.0/21/26, 0.0459633806858544,  0.023493029705930257 ],
	[ 'scipy testRepeatedValues x2356 lt',  \@X2356, \@X3467, 'less',
	  70.0/21/26,  0.6121593130022775,  0.38140754084210976 ],
	[ 'scipy testEqualSizes +1 two', \@D2, \@D2_P1, 'two.sided', 1.0/3, 1.0,  1.0 ],
	[ 'scipy testEqualSizes +1 gt',  \@D2, \@D2_P1, 'greater',   1.0/3, 0.75, 0.75 ],
	[ 'scipy testEqualSizes +1 lt',  \@D2, \@D2_P1, 'less',      0.0/3, 1.0,  1.0 ],
);

for my $row (@SCIPY_TIED) {
	my ($label, $x, $y, $alt, $d_want, $p_scipy, $p_r) = @$row;
	my ($r, $warns) = call_ks($x, $y, alternative => $alt, exact => 1);
	d_ok($r->{statistic}, $d_want, "diverge $label");
	is(scalar(grep { $_ =~ $WARN_RE{ties} } @$warns), 1,
		"diverge $label: warns about ties") or diag("warnings: @$warns");
	# Where the true D is 0 every method agrees on p = 1; elsewhere all three
	# differ, and that is the point being recorded.
	if ($d_want == 0) {
		p_ok($r->{p_value}, 1, $TOL_P, "diverge $label: D = 0 so p = 1 everywhere");
	}
	else {
		ok($r->{p_value} != $p_scipy && $r->{p_value} != $p_r,
			sprintf('diverge %s: ks_test %.17g, SciPy %.17g, R %.17g',
				$label, $r->{p_value}, $p_scipy, $p_r));
	}
}

# R's documented tie examples, restated as the fractions R's man page prints,
# so that the day the tie-conditional DP lands these two lines are the ones
# that flip.  ?ks.test says of the Schroeer & Trenkler pair "D = 3/7,
# p = 8/33 = 0.242424.."; ?qqplot's knee-angle example prints D = 0.225,
# p-value = 0.212.
{
	my ($st) = call_ks(\@ST_X, \@ST_Y);
	d_ok($st->{statistic}, 3 / 7, 'ks.test.Rd: Schroeer & Trenkler D = 3/7');
	ok(abs($st->{p_value} - 8 / 33) > 1e-6,
		sprintf('ks.test.Rd: exact p = 8/33 not yet reachable (got %.17g)',
			$st->{p_value}));

	my ($sw) = call_ks(\@SW_F, \@SW_M);
	d_ok($sw->{statistic}, 0.225, 'qqplot.Rd: Switzer knee-angle D = 0.225');
	ok(abs($sw->{p_value} - 0.21198990394624936) > 1e-6,
		sprintf('qqplot.Rd: exact p = 0.212 not yet reachable (got %.17g)',
			$sw->{p_value}));

	# ?ks.test prints "D = 0.53846, p-value = 0.0006919" for the Ozone
	# columns; the statistic is asserted above, the p-value is not reachable.
	my ($oz) = call_ks(\@OZ5, \@OZ8);
	is(sprintf('%.7f', $oz->{p_value}), '0.0010644',
		'ks.test.Rd: Ozone p-value is the asymptotic 0.0010644, not R\'s 0.0006919');
}

done_testing();
