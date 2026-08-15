#!/usr/bin/env perl
#
# Cross-validation of wilcox_test() against the two reference implementations,
# using their own test suites, regression tests and man-page examples rather
# than cases invented here.  t/wilcox_test.t covers the call forms, argument
# validation and leak checks; this file does not repeat those.
#
# Provenance of every expected value below:
#
#   * R 4.6.1 (2026-06-24) "Happy Hop", stats::wilcox.test() -- the function
#     wilcox_test() is modelled on.  Note that 4.6.0 is the release in which
#     wilcox.test() gained exact (conditional) inference in the presence of
#     ties, via Torsten Hothorn's implementation of the Streitberg-Roehmel
#     shift algorithm (doc/NEWS.Rd), and gained the Edgeworth series reachable
#     through its integer 'correct'.  Values taken from an older R will not
#     match: tests/reg-tests-1d.R says so itself, at the degenerate one-sample
#     cases reproduced below ("For R >= 4.6.0 warnings for exact with ties are
#     gone").  The @CORPUS block was generated at options(digits=17) by
#     t/wilcox_test.R.scipy.R, which is committed next to this file and says
#     at the top how to re-run it.  The test never calls it.
#   * R's own suite:
#       - tests/reg-tests-1a.R, the PR#1150 Hollander & Wolfe conf.int cases
#         (@HOLLANDER_WOLFE), whose numbers upstream annotates as coming from
#         Hollander & Wolfe (1999) 2nd ed., pp. 40, 53, 111 and 126;
#       - tests/reg-tests-1b.R, the Wolfgang Huber wilcox.test(1, 2:60) case
#         and the "(asymptotic) point estimate does not depend on
#         'alternative'" check;
#       - tests/reg-tests-1d.R, the six degenerate one-sample calls at line
#         332 and the +/-Inf identities at line 3525;
#       - src/library/stats/man/wilcox.test.Rd and the pinned output of its
#         examples in tests/Examples/stats-Ex.Rout.save, including the
#         airquality Ozone case (whose W is a half-integer, so it exercises
#         the tied exact path) and the digits.rank example.
#   * SciPy 1.17.1:
#       - scipy/stats/tests/test_hypotests.py::TestMannWhitneyU, whose header
#         reads "All magic numbers are from R wilcox.test": cases_basic,
#         cases_continuity, cases_9184, cases_2118, test_tie_correct,
#         test_exact_U_equals_mean, test_gh_11355b (+/-Inf) and
#         test_mannwhitneyu_{one,two}_sided;
#       - scipy/stats/tests/test_morestats.py::TestWilcoxon:
#         test_accuracy_wilcoxon, test_wilcoxon_tie, test_onesided,
#         test_exact_pval, test_exact_p_1, test_all_zeros_exact and
#         test_symmetry_gh19872_gh20752.  SciPy reports min(T+, T-) where R
#         and this module report V, so only the p-values carry over from the
#         signed-rank cases; where SciPy pins a statistic that is R's, it is
#         checked too.
#
# Deliberate divergences from R are asserted at the end of the file rather
# than skipped, so that changing one later is a deliberate act.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR 'wilcox_test';

# Tolerances.
#
# $TOL_P is the p-value limit.  Over the 663 generated cases plus every
# targeted case below, this build's worst disagreement with R is 1.7e-11, and
# it comes from two places, neither of which is wilcox_test() being sloppy:
#
#   * exact tests on tied data.  R's dpermdist2() divides each density entry
#     by the permutation count before summing a tail; wilcox_test() sums the
#     integer counts and divides once, so the two differ by the rounding R
#     does per entry.  Checked against exact rational arithmetic for the worst
#     case in the corpus (a 11-vs-12 tied rank sum, p = 4/676039): this
#     module returns the correctly rounded double and R is 1.2e-11 high.
#   * asymptotic tails below about 1e-5, where approx_pnorm()'s erfc differs
#     from R's Cody pnorm in the last few digits.
#
# 1e-9 therefore leaves two orders of headroom for long-double and quadmath
# builds, where the same expressions associate differently.
my $TOL_P = 1e-9;

# $TOL_STAT is for W and V.  These are sums of half-integers and are exact in
# any NV width; the limit is only here to allow the comparison at all.
my $TOL_STAT = 1e-12;

# $TOL_CI covers the estimate and the interval bounds.  The exact intervals
# are order statistics of the pairwise differences, so they are exact; the
# asymptotic ones come out of a root search, which the corpus runs at
# tol.root = 1e-12 (see the generator) so that the frozen limits are a
# property of the data rather than of where Brent's method happened to stop.
#
# $TOL_CI_ABS is the absolute floor, and it is not decoration: the estimate is
# the root of a step function, and where that root is exactly 0 both R and this
# module land a couple of hundred femto-units away from it -- 1.98e-13 against
# 1.98e-13, agreeing to every digit that means anything and to none that a
# relative test would look at.  1e-9 is still three orders tighter than
# tol.root's own default and far below the smallest real location shift in the
# corpus, so it cannot hide a wrong answer.
my $TOL_CI     = 1e-8;
my $TOL_CI_ABS = 1e-9;

# The exact-with-ties confidence interval rebuilds a permutation distribution
# at every candidate shift; at m = n = 30 that is about 1.5 seconds here and
# 0.8 in R.  Nothing else in this file takes more than a few milliseconds.
my $EXTENDED = $ENV{EXTENDED_TESTING} || $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING};

# Relative compare with an absolute fallback at exactly 0, plus explicit
# handling of the non-finite bounds an unbounded one-sided interval carries.
sub close_to {
	my ($got, $want, $tol, $name, $atol) = @_;
	if (!defined $want) { ok(!defined $got, "$name: undef"); return }
	if ($want eq 'Inf' or $want eq '-Inf') {
		my $sign = ($want eq '-Inf') ? -1 : 1;
		ok(defined $got && $got == $sign * 9**9**9, "$name: $want")
			or diag("         got: " . (defined $got ? $got : 'undef') . "\n    expected: $want");
		return;
	}
	if ($want eq 'NaN') { ok(defined $got && $got != $got, "$name: NaN"); return }
	my $diff = abs($got - $want);
	return ok(1, $name) if defined $atol && $diff <= $atol;
	my $rel  = abs($want) > 1e-300 ? $diff / abs($want) : $diff;
	ok($rel <= $tol, $name)
		or diag(sprintf("         got: %.17g\n    expected: %.17g\n         rel: %.3g (limit %.3g)",
		                $got, $want, $rel, $tol));
}

# ===========================================================================
# 1. R corpus sweep
#
# 663 calls generated by t/wilcox_test.R.scipy.R.  Each row is
#   [ x-key, y-key, paired, alternative, mu, correct, exact, conf.int,
#     conf.level, W|V, p, method, estimate, lo, hi, achieved conf.level ]
# with y-key "" meaning a one-sample call and exact undef meaning "let it
# decide".  The named samples are laid out so the sweep reaches every branch:
# untied (closed-form exact distribution), tied (exact conditional inference
# given the observed ranks), integer-valued (heavy ties plus exact zeroes once
# mu is subtracted), shifted (far-apart one-sided tails), and the degenerate
# single-point / all-identical / all-zero cases.
# ===========================================================================

# BEGIN GENERATED CORPUS -- regenerate with t/wilcox_test.R.scipy.R
my %DATA = (
	a4     => [-2.158203125,0.2626953125,-0.38671875,1.4404296875],
	a9     => [-0.81640625,-1.6513671875,0.3798828125,-0.697265625,0.08984375,-0.337890625,-0.8662109375,-1.5556640625,0.271484375],
	a15    => [-1.7216796875,0.4970703125,0.8955078125,0.484375,-0.591796875,0.26171875,-1.22265625,-1.833984375,1.4375,0.8212890625,0.21484375,-1.1748046875,2.1123046875,1.0947265625,0.572265625],
	a7     => [1.84765625,-0.76171875,0.154296875,-2.09765625,-0.5947265625,-0.169921875,0.2548828125],
	b9     => [-0.25,-1,-0,0,0.25,-1,0,0.25,0.75],
	b15    => [1.75,0,-0.5,-0.5,0.5,-1.25,-0,-1,1.5,1.25,-1,-1.25,1,1,-0.75],
	b12    => [-1,-1.75,-1.5,-0.5,1,-2.25,-0.5,2.5,-1.75,0.5,0.5,-0.75],
	c9     => [1,-1,0,-1,-1,-2,2,-1,2],
	c15    => [2,2,1,-2,0,-2,1,-2,-2,-1,-2,1,-1,1,-2],
	c12    => [0,2,-1,-1,2,2,-1,-2,0,0,0,2],
	d9     => [0.92578125,1.71875,3.1171875,1.5439453125,0.986328125,3.095703125,0.2724609375,1.9892578125,2.67578125],
	d15    => [2.208984375,1.9599609375,0.99609375,1.8916015625,-0.037109375,1.6201171875,0.47265625,0.783203125,1.2666015625,0.826171875,1.33984375,1.5166015625,1.3232421875,2.255859375,0.3681640625],
	d12    => [2.712890625,1.7451171875,0.916015625,0.6259765625,3.2001953125,1.4208984375,1.9462890625,2.6845703125,2.931640625,0.1142578125,0.83984375,1.314453125],
	e1     => [2.5],
	e2     => [1.5,4.25],
	eflat  => [3,3,3,3,3,3],
	ezero  => [0,0,0,0,0],
	emix   => [-1,0,1,0,2],
);
my @CORPUS = (
	['a4','a9',0,'two.sided',0,1,undef,0,0.90000000000000002,21,0.71048951048951048,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a9','b9',0,'two.sided',0.5,1,undef,0,0.98999999999999999,10,0.0051007815713698069,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['b9','c9',0,'two.sided',-1,1,undef,1,0.94999999999999996,57.5,0.13776223776223784,'Wilcoxon rank sum exact test',0,-1.25,1.25,0.96772932949403534],
	['c9','d9',0,'two.sided',0,1,undef,0,0.90000000000000002,15,0.022377622377622378,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a15','d15',0,'two.sided',0,1,undef,0,0.98999999999999999,48,0.0065680524031070109,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['b15','c15',0,'two.sided',0.5,1,undef,1,0.94999999999999996,119.5,0.78114910552979455,'Wilcoxon rank sum exact test',0.75,-0.75,1.5,0.96618472239628383],
	['d12','b12',0,'two.sided',-1,1,undef,0,0.90000000000000002,138,1.9229659827368906e-05,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['c12','a7',0,'two.sided',0,1,undef,0,0.98999999999999999,48,0.63058664761451144,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['e1','a9',0,'two.sided',0,1,undef,1,0.94999999999999996,9,0.20000000000000001,'Wilcoxon rank sum exact test',3.197265625,'-Inf','Inf',1],
	['e2','c9',0,'two.sided',0.5,1,undef,0,0.90000000000000002,15.5,0.18181818181818188,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['eflat','eflat',0,'two.sided',-1,1,undef,0,0.98999999999999999,36,0.0021645021645022577,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['ezero','emix',0,'two.sided',0,1,undef,1,0.94999999999999996,10,0.72222222222222221,'Wilcoxon rank sum exact test',0,-2,0,0.95238095238095233],
	['a9','a9',0,'two.sided',0,1,undef,0,0.90000000000000002,40.5,1,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['b12','c12',0,'two.sided',0.5,1,undef,0,0.98999999999999999,37.5,0.042555976800155021,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a9','b9',1,'two.sided',-1,1,undef,1,0.94999999999999996,39,0.0546875,'Wilcoxon signed rank exact test',-0.5224609375,-1.14208984375,0.091796875,0.9609375],
	['b9','c9',1,'two.sided',0,1,undef,0,0.90000000000000002,20,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a15','d15',1,'two.sided',0,1,undef,0,0.98999999999999999,13,0.0053710937500000017,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b15','c15',1,'two.sided',0.5,1,undef,1,0.94999999999999996,60,0.989501953125,'Wilcoxon signed rank exact test',0.5,-0.5,1.375,0.9527587890625],
	['d12','b12',1,'two.sided',-1,1,undef,0,0.90000000000000002,78,0.00048828125000000033,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['eflat','eflat',1,'two.sided',0,1,undef,0,0.98999999999999999,0,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['ezero','emix',1,'two.sided',0,1,undef,1,0.94999999999999996,3.5,0.75,'Wilcoxon signed rank exact test',-0.5,-2,'Inf',1],
	['a9','a9',1,'two.sided',0.5,1,undef,0,0.90000000000000002,0,0.00390625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b12','c12',1,'two.sided',-1,1,undef,0,0.98999999999999999,41,0.802734375,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a4','',0,'two.sided',0,1,undef,1,0.94999999999999996,4,0.875,'Wilcoxon signed rank exact test',-0.21044921875,'-Inf','Inf',1],
	['a9','',0,'two.sided',0,1,undef,0,0.90000000000000002,7,0.07421875,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a15','',0,'two.sided',0.5,1,undef,0,0.98999999999999999,44,0.38940429687500006,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b9','',0,'two.sided',-1,1,undef,1,0.94999999999999996,42,0.015625,'Wilcoxon signed rank exact test',0,-0.5,0.375,0.97265625],
	['b15','',0,'two.sided',0,1,undef,0,0.90000000000000002,62,0.8564453125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['c9','',0,'two.sided',0,1,undef,0,0.98999999999999999,20,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['c15','',0,'two.sided',0.5,1,undef,1,0.94999999999999996,27,0.05828857421875,'Wilcoxon signed rank exact test',-0.5,-1.5,0.5,0.959625244140625],
	['d9','',0,'two.sided',-1,1,undef,0,0.90000000000000002,45,0.00390625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['d15','',0,'two.sided',0,1,undef,0,0.98999999999999999,119,0.00012207031250000005,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['e1','',0,'two.sided',0,1,undef,1,0.94999999999999996,1,1,'Wilcoxon signed rank exact test',2.5,'-Inf','Inf',1],
	['e2','',0,'two.sided',0.5,1,undef,0,0.90000000000000002,3,0.5,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['eflat','',0,'two.sided',-1,1,undef,0,0.98999999999999999,21,0.03125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['ezero','',0,'two.sided',0,1,undef,1,0.94999999999999996,0,1,'Wilcoxon signed rank exact test',0,0,'Inf',1],
	['emix','',0,'two.sided',0,1,undef,0,0.90000000000000002,8.5,0.75,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a4','a9',0,'two.sided',0.5,0,undef,0,0.98999999999999999,17,0.93986013986013994,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a9','b9',0,'two.sided',-1,0,undef,1,0.94999999999999996,59,0.10723981900452495,'Wilcoxon rank sum exact test',-0.5556640625,-1.1162109375,0.271484375,0.95524475524475516],
	['b9','c9',0,'two.sided',0,0,undef,0,0.90000000000000002,45.5,0.67856849033319611,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['c9','d9',0,'two.sided',0,0,undef,0,0.98999999999999999,15,0.022377622377622378,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a15','d15',0,'two.sided',0.5,0,undef,1,0.94999999999999996,24,8.9789986327785536e-05,'Wilcoxon rank sum exact test',-1.0517578125,-1.8583984375,-0.2861328125,0.95466610090207737],
	['b15','c15',0,'two.sided',-1,0,undef,0,0.90000000000000002,168,0.018915000703982443,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['d12','b12',0,'two.sided',0,0,undef,0,0.98999999999999999,130,0.00034095666078437503,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['c12','a7',0,'two.sided',0,0,undef,1,0.94999999999999996,48,0.63058664761451144,'Wilcoxon rank sum exact test',0.169921875,-1.154296875,2.09765625,0.96253076129237125],
	['e1','a9',0,'two.sided',0.5,0,undef,0,0.90000000000000002,9,0.20000000000000001,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['e2','c9',0,'two.sided',-1,0,undef,0,0.98999999999999999,18,0.036363636363636376,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['eflat','eflat',0,'two.sided',0,0,undef,1,0.94999999999999996,18,1,'Wilcoxon rank sum exact test',0,0,0,1],
	['ezero','emix',0,'two.sided',0,0,undef,0,0.90000000000000002,10,0.72222222222222221,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a9','a9',0,'two.sided',0.5,0,undef,0,0.98999999999999999,26,0.22241875771287536,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['b12','c12',0,'two.sided',-1,0,undef,1,0.94999999999999996,81,0.61632760831845501,'Wilcoxon rank sum exact test',-0.75,-1.75,0.5,0.96072268020040263],
	['a9','b9',1,'two.sided',0,0,undef,0,0.90000000000000002,8,0.09765625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b9','c9',1,'two.sided',0,0,undef,0,0.98999999999999999,20,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a15','d15',1,'two.sided',0.5,0,undef,1,0.94999999999999996,1,0.00012207031250000005,'Wilcoxon signed rank exact test',-1.134033203125,-1.88916015625,-0.453125,0.95208740234375],
	['b15','c15',1,'two.sided',-1,0,undef,0,0.90000000000000002,106.5,0.005126953125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['d12','b12',1,'two.sided',0,0,undef,0,0.98999999999999999,75,0.0024414062500000017,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['eflat','eflat',1,'two.sided',0,0,undef,1,0.94999999999999996,0,1,'Wilcoxon signed rank exact test',0,0,0,0.984375],
	['ezero','emix',1,'two.sided',0.5,0,undef,0,0.90000000000000002,2,0.25,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a9','a9',1,'two.sided',-1,0,undef,0,0.98999999999999999,45,0.00390625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b12','c12',1,'two.sided',0,0,undef,1,0.94999999999999996,24,0.25390625,'Wilcoxon signed rank exact test',-0.6875,-2.125,0.5,0.968994140625],
	['a4','',0,'two.sided',0,0,undef,0,0.90000000000000002,4,0.875,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a9','',0,'two.sided',0.5,0,undef,0,0.98999999999999999,0,0.00390625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a15','',0,'two.sided',-1,0,undef,1,0.94999999999999996,108,0.0042724609375000017,'Wilcoxon signed rank exact test',0.205078125,-0.50634765625,0.8212890625,0.95208740234375],
	['b9','',0,'two.sided',0,0,undef,0,0.90000000000000002,17,0.8125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b15','',0,'two.sided',0,0,undef,0,0.98999999999999999,62,0.8564453125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['c9','',0,'two.sided',0.5,0,undef,1,0.94999999999999996,12.5,0.30078125,'Wilcoxon signed rank exact test',0,-1,1,0.96875],
	['c15','',0,'two.sided',-1,0,undef,0,0.90000000000000002,81,0.219970703125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['d9','',0,'two.sided',0,0,undef,0,0.98999999999999999,45,0.00390625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['d15','',0,'two.sided',0,0,undef,1,0.94999999999999996,119,0.00012207031250000005,'Wilcoxon signed rank exact test',1.291748046875,0.85400390625,1.6416015625,0.95208740234375],
	['e1','',0,'two.sided',0.5,0,undef,0,0.90000000000000002,1,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['e2','',0,'two.sided',-1,0,undef,0,0.98999999999999999,3,0.5,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['eflat','',0,'two.sided',0,0,undef,1,0.94999999999999996,21,0.03125,'Wilcoxon signed rank exact test',3,3,3,0.984375],
	['ezero','',0,'two.sided',0,0,undef,0,0.90000000000000002,0,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['emix','',0,'two.sided',0.5,0,undef,0,0.98999999999999999,6.5,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a4','a9',0,'two.sided',-1,1,1,1,0.94999999999999996,29,0.1062937062937063,'Wilcoxon rank sum exact test',0.45458984375,-1.4609375,2.1376953125,0.96643356643356648],
	['a9','b9',0,'two.sided',0,1,1,0,0.90000000000000002,30,0.37326203208556152,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['b9','c9',0,'two.sided',0,1,1,0,0.98999999999999999,45.5,0.67856849033319611,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['c9','d9',0,'two.sided',0.5,1,1,1,0.94999999999999996,7,0.0016454134101192923,'Wilcoxon rank sum exact test',-1.986328125,-3.1171875,-0.67578125,0.95386672151378027],
	['a15','d15',0,'two.sided',-1,1,1,0,0.90000000000000002,108,0.87019445643535298,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['b15','c15',0,'two.sided',0,1,1,0,0.98999999999999999,137,0.3144204987289636,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['d12','b12',0,'two.sided',0,1,1,1,0.94999999999999996,130,0.00034095666078437503,'Wilcoxon rank sum exact test',2.27978515625,1.2451171875,3.212890625,0.95007277686642344],
	['c12','a7',0,'two.sided',0.5,1,1,0,0.90000000000000002,39,0.81995713265063108,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['e1','a9',0,'two.sided',-1,1,1,0,0.98999999999999999,9,0.20000000000000001,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['e2','c9',0,'two.sided',0,1,1,1,0.94999999999999996,16,0.1454545454545455,'Wilcoxon rank sum exact test',2.5,-0.5,6.25,1],
	['eflat','eflat',0,'two.sided',0,1,1,0,0.90000000000000002,18,1,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['ezero','emix',0,'two.sided',0.5,1,1,0,0.98999999999999999,5,0.047619047619047616,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a9','a9',0,'two.sided',-1,1,1,1,0.94999999999999996,68,0.014191690662278898,'Wilcoxon rank sum exact test',0,-0.8583984375,0.8583984375,0.96001645413410119],
	['b12','c12',0,'two.sided',0,1,1,0,0.90000000000000002,53.5,0.29526994744386048,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a9','b9',1,'two.sided',0,1,1,0,0.98999999999999999,8,0.09765625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b9','c9',1,'two.sided',0.5,1,1,1,0.94999999999999996,16,0.48046875,'Wilcoxon signed rank exact test',0,-1,1.125,0.9609375],
	['a15','d15',1,'two.sided',-1,1,1,0,0.90000000000000002,57,0.89038085937500011,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b15','c15',1,'two.sided',0,1,1,0,0.98999999999999999,76.5,0.3525390625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['d12','b12',1,'two.sided',0,1,1,1,0.94999999999999996,75,0.0024414062500000017,'Wilcoxon signed rank exact test',2.22021484375,1.12451171875,3.373046875,0.95751953125],
	['eflat','eflat',1,'two.sided',0.5,1,1,0,0.90000000000000002,0,0.03125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['ezero','emix',1,'two.sided',-1,1,1,0,0.98999999999999999,11,0.5,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a9','a9',1,'two.sided',0,1,1,1,0.94999999999999996,0,1,'Wilcoxon signed rank exact test',0,0,0,0.998046875],
	['b12','c12',1,'two.sided',0,1,1,0,0.90000000000000002,24,0.25390625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a4','',0,'two.sided',0.5,1,1,0,0.98999999999999999,3,0.625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a9','',0,'two.sided',-1,1,1,1,0.94999999999999996,36,0.12890625,'Wilcoxon signed rank exact test',-0.60205078125,-1.2109375,0.08984375,0.9609375],
	['a15','',0,'two.sided',0,1,1,0,0.90000000000000002,66,0.76153564453125011,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b9','',0,'two.sided',0,1,1,0,0.98999999999999999,17,0.8125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b15','',0,'two.sided',0.5,1,1,1,0.94999999999999996,31.5,0.1138916015625,'Wilcoxon signed rank exact test',0,-0.625,0.625,0.955535888671875],
	['c9','',0,'two.sided',-1,1,1,0,0.90000000000000002,29.5,0.1875,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['c15','',0,'two.sided',0,1,1,0,0.98999999999999999,41,0.31298828125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['d9','',0,'two.sided',0,1,1,1,0.94999999999999996,45,0.00390625,'Wilcoxon signed rank exact test',1.80078125,0.9560546875,2.67578125,0.9609375],
	['d15','',0,'two.sided',0.5,1,1,0,0.90000000000000002,111,0.0020141601562500009,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['e1','',0,'two.sided',-1,1,1,0,0.98999999999999999,1,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['e2','',0,'two.sided',0,1,1,1,0.94999999999999996,3,0.5,'Wilcoxon signed rank exact test',2.875,'-Inf','Inf',1],
	['eflat','',0,'two.sided',0,1,1,0,0.90000000000000002,21,0.03125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['ezero','',0,'two.sided',0.5,1,1,0,0.98999999999999999,0,0.0625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['emix','',0,'two.sided',-1,1,1,1,0.94999999999999996,14,0.125,'Wilcoxon signed rank exact test',0.5,-1,'Inf',1],
	['a4','a9',0,'two.sided',0,0,1,0,0.90000000000000002,21,0.71048951048951048,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a9','b9',0,'two.sided',0,0,1,0,0.98999999999999999,30,0.37326203208556152,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['b9','c9',0,'two.sided',0.5,0,1,1,0.94999999999999996,38,0.84537227478403953,'Wilcoxon rank sum exact test',0,-1.25,1.25,0.96772932949403534],
	['c9','d9',0,'two.sided',-1,0,1,0,0.90000000000000002,23,0.12780748663101604,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a15','d15',0,'two.sided',0,0,1,0,0.98999999999999999,48,0.0065680524031070109,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['b15','c15',0,'two.sided',0,0,1,1,0.94999999999999996,137,0.3144204987289636,'Wilcoxon rank sum exact test',0.75,-0.75,1.5,0.96618472239628383],
	['d12','b12',0,'two.sided',0.5,0,1,0,0.90000000000000002,119,0.0052519159397608206,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['c12','a7',0,'two.sided',-1,0,1,0,0.98999999999999999,65,0.050408827498610753,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['e1','a9',0,'two.sided',0,0,1,1,0.94999999999999996,9,0.20000000000000001,'Wilcoxon rank sum exact test',3.197265625,'-Inf','Inf',1],
	['e2','c9',0,'two.sided',0,0,1,0,0.90000000000000002,16,0.1454545454545455,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['eflat','eflat',0,'two.sided',0.5,0,1,0,0.98999999999999999,0,0.0021645021645021645,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['ezero','emix',0,'two.sided',-1,0,1,1,0.94999999999999996,17.5,0.16666666666666674,'Wilcoxon rank sum exact test',0,-2,0,0.95238095238095233],
	['a9','a9',0,'two.sided',0,0,1,0,0.90000000000000002,40.5,1,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['b12','c12',0,'two.sided',0,0,1,0,0.98999999999999999,53.5,0.29526994744386048,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a9','b9',1,'two.sided',0.5,0,1,1,0.94999999999999996,2,0.01171875,'Wilcoxon signed rank exact test',-0.5224609375,-1.14208984375,0.091796875,0.9609375],
	['b9','c9',1,'two.sided',-1,0,1,0,0.90000000000000002,38,0.0703125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a15','d15',1,'two.sided',0,0,1,0,0.98999999999999999,13,0.0053710937500000017,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b15','c15',1,'two.sided',0,0,1,1,0.94999999999999996,76.5,0.3525390625,'Wilcoxon signed rank exact test',0.5,-0.5,1.375,0.9527587890625],
	['d12','b12',1,'two.sided',0.5,0,1,0,0.90000000000000002,71,0.0092773437500000069,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['eflat','eflat',1,'two.sided',-1,0,1,0,0.98999999999999999,21,0.03125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['ezero','emix',1,'two.sided',0,0,1,1,0.94999999999999996,3.5,0.75,'Wilcoxon signed rank exact test',-0.5,-2,'Inf',1],
	['a9','a9',1,'two.sided',0,0,1,0,0.90000000000000002,0,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b12','c12',1,'two.sided',0.5,0,1,0,0.98999999999999999,10,0.0546875,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a4','',0,'two.sided',-1,0,1,1,0.94999999999999996,8,0.375,'Wilcoxon signed rank exact test',-0.21044921875,'-Inf','Inf',1],
	['a9','',0,'two.sided',0,0,1,0,0.90000000000000002,7,0.07421875,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a15','',0,'two.sided',0,0,1,0,0.98999999999999999,66,0.76153564453125011,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b9','',0,'two.sided',0.5,0,1,1,0.94999999999999996,2,0.015625,'Wilcoxon signed rank exact test',0,-0.5,0.375,0.97265625],
	['b15','',0,'two.sided',-1,0,1,0,0.90000000000000002,109,0.002197265625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['c9','',0,'two.sided',0,0,1,0,0.98999999999999999,20,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['c15','',0,'two.sided',0,0,1,1,0.94999999999999996,41,0.31298828125,'Wilcoxon signed rank exact test',-0.5,-1.5,0.5,0.959625244140625],
	['d9','',0,'two.sided',0.5,0,1,0,0.90000000000000002,44,0.0078125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['d15','',0,'two.sided',-1,0,1,0,0.98999999999999999,120,6.1035156250000027e-05,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['e1','',0,'two.sided',0,0,1,1,0.94999999999999996,1,1,'Wilcoxon signed rank exact test',2.5,'-Inf','Inf',1],
	['e2','',0,'two.sided',0,0,1,0,0.90000000000000002,3,0.5,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['eflat','',0,'two.sided',0.5,0,1,0,0.98999999999999999,21,0.03125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['ezero','',0,'two.sided',-1,0,1,1,0.94999999999999996,15,0.0625,'Wilcoxon signed rank exact test',0,0,'Inf',1],
	['emix','',0,'two.sided',0,0,1,0,0.90000000000000002,8.5,0.75,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a4','a9',0,'two.sided',0,1,0,0,0.98999999999999999,21,0.69967562563470498,'Wilcoxon rank sum test with continuity correction',undef,undef,undef,undef],
	['a9','b9',0,'two.sided',0.5,1,0,1,0.94999999999999996,10,0.0078768275893845614,'Wilcoxon rank sum test with continuity correction',-0.55566406250039169,-1.1162109375008611,0.27148437499997469,0.94999999999999996],
	['b9','c9',0,'two.sided',-1,1,0,0,0.90000000000000002,57.5,0.13969313741821288,'Wilcoxon rank sum test with continuity correction',undef,undef,undef,undef],
	['c9','d9',0,'two.sided',0,1,0,0,0.98999999999999999,15,0.026405764078511477,'Wilcoxon rank sum test with continuity correction',undef,undef,undef,undef],
	['a15','d15',0,'two.sided',0,1,0,1,0.94999999999999996,48,0.0079403362642465822,'Wilcoxon rank sum test with continuity correction',-1.0517578125002252,-1.8583984374998224,-0.28613281250050904,0.94999999999999996],
	['b15','c15',0,'two.sided',0.5,1,0,0,0.90000000000000002,119.5,0.78580481733753071,'Wilcoxon rank sum test with continuity correction',undef,undef,undef,undef],
	['d12','b12',0,'two.sided',-1,1,0,0,0.98999999999999999,138,0.00015425775026067789,'Wilcoxon rank sum test with continuity correction',undef,undef,undef,undef],
	['c12','a7',0,'two.sided',0,1,0,1,0.94999999999999996,48,0.63849328638753367,'Wilcoxon rank sum test with continuity correction',0.16992187499965528,-1.1542968749994404,2.0976562499999334,0.94999999999999996],
	['e1','a9',0,'two.sided',0,1,0,0,0.90000000000000002,9,0.16373435432459216,'Wilcoxon rank sum test with continuity correction',undef,undef,undef,undef],
	['e2','c9',0,'two.sided',0.5,1,0,0,0.98999999999999999,15.5,0.14582541398394833,'Wilcoxon rank sum test with continuity correction',undef,undef,undef,undef],
	['ezero','emix',0,'two.sided',0,1,0,0,0.90000000000000002,10,0.60723554377411126,'Wilcoxon rank sum test with continuity correction',undef,undef,undef,undef],
	['a9','a9',0,'two.sided',0,1,0,0,0.98999999999999999,40.5,1,'Wilcoxon rank sum test with continuity correction',undef,undef,undef,undef],
	['b12','c12',0,'two.sided',0.5,1,0,1,0.94999999999999996,37.5,0.045857952847435636,'Wilcoxon rank sum test with continuity correction',-0.74999999999996247,-1.7500000000005673,0.49999999999995209,0.94999999999999996],
	['a9','b9',1,'two.sided',-1,1,0,0,0.90000000000000002,39,0.058024019946221417,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['b9','c9',1,'two.sided',0,1,0,0,0.98999999999999999,12,0.79588341133641594,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['a15','d15',1,'two.sided',0,1,0,1,0.94999999999999996,13,0.0082656222717715569,'Wilcoxon signed rank test with continuity correction',-1.1361067140523757,-1.9082031249995535,-0.3369140625004261,0.94999999999999996],
	['b15','c15',1,'two.sided',0.5,1,0,0,0.90000000000000002,52,1,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['d12','b12',1,'two.sided',-1,1,0,0,0.98999999999999999,78,0.0025261742685021016,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['eflat','eflat',1,'two.sided',0,1,0,1,0.94999999999999996,0,'NaN','Wilcoxon signed rank test with continuity correction',0,'NaN','NaN',0],
	['ezero','emix',1,'two.sided',0,1,0,0,0.90000000000000002,1.5,0.58621368107313998,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['a9','a9',1,'two.sided',0.5,1,0,0,0.98999999999999999,0,0.003353436454946325,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['b12','c12',1,'two.sided',-1,1,0,1,0.94999999999999996,29,0.91828216102747029,'Wilcoxon signed rank test with continuity correction',-0.70304928468751926,-2.2499999999999831,0.50000000000064815,0.94999999999999996],
	['a4','',0,'two.sided',0,1,0,0,0.90000000000000002,4,0.85513214058470588,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['a9','',0,'two.sided',0,1,0,0,0.98999999999999999,7,0.075560567525941327,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['a15','',0,'two.sided',0.5,1,0,1,0.94999999999999996,44,0.37867469302308499,'Wilcoxon signed rank test with continuity correction',0.1973870985846666,-0.57470703124978695,0.82617187499964895,0.94999999999999996],
	['b9','',0,'two.sided',-1,1,0,0,0.90000000000000002,28,0.021303176178702588,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['b15','',0,'two.sided',0,1,0,0,0.98999999999999999,50,0.77864033738085969,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['c9','',0,'two.sided',0,1,0,1,0.94999999999999996,17,0.94246758741441883,'Wilcoxon signed rank test with continuity correction',-3.5521469657121746e-13,-1.000000000000077,1.0000000000001896,0.94999999999999996],
	['c15','',0,'two.sided',0.5,1,0,0,0.90000000000000002,27,0.061407202346100885,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['d9','',0,'two.sided',-1,1,0,0,0.98999999999999999,45,0.0091516888526501639,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['d15','',0,'two.sided',0,1,0,1,0.94999999999999996,119,0.00089190137705918993,'Wilcoxon signed rank test with continuity correction',1.2932737037706583,0.8457031250003938,1.6499023437498788,0.94999999999999996],
	['e1','',0,'two.sided',0,1,0,0,0.90000000000000002,1,1,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['e2','',0,'two.sided',0.5,1,0,0,0.98999999999999999,3,0.37109336952269745,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['eflat','',0,'two.sided',-1,1,0,1,0.94999999999999996,21,0.019656157250169892,'Wilcoxon signed rank test with continuity correction',3,'NaN','NaN',0],
	['ezero','',0,'two.sided',0,1,0,0,0.90000000000000002,0,'NaN','Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['emix','',0,'two.sided',0,1,0,0,0.98999999999999999,4.5,0.58621368107313998,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['a4','a9',0,'two.sided',0.5,0,0,1,0.94999999999999996,17,0.87737055606414338,'Wilcoxon rank sum test',0.4690926266724697,-1.3417968750005063,1.9140625000000147,0.94999999999999996],
	['a9','b9',0,'two.sided',-1,0,0,0,0.90000000000000002,59,0.10128178225231066,'Wilcoxon rank sum test',undef,undef,undef,undef],
	['b9','c9',0,'two.sided',0,0,0,0,0.98999999999999999,45.5,0.65081938843021403,'Wilcoxon rank sum test',undef,undef,undef,undef],
	['c9','d9',0,'two.sided',0,0,0,1,0.94999999999999996,15,0.023537517315430131,'Wilcoxon rank sum test',-1.9863281250008504,-3.1171875000000377,-0.67578125000040179,0.94999999999999996],
	['a15','d15',0,'two.sided',0.5,0,0,0,0.90000000000000002,24,0.00024178397387425465,'Wilcoxon rank sum test',undef,undef,undef,undef],
	['b15','c15',0,'two.sided',-1,0,0,0,0.98999999999999999,168,0.02009126134274708,'Wilcoxon rank sum test',undef,undef,undef,undef],
	['d12','b12',0,'two.sided',0,0,0,1,0.94999999999999996,130,0.00080573357959345948,'Wilcoxon rank sum test',2.2649590442709315,1.2451171874996558,3.2128906250001741,0.94999999999999996],
	['c12','a7',0,'two.sided',0,0,0,0,0.90000000000000002,48,0.6082898155651828,'Wilcoxon rank sum test',undef,undef,undef,undef],
	['e1','a9',0,'two.sided',0.5,0,0,0,0.98999999999999999,9,0.11718508719813814,'Wilcoxon rank sum test',undef,undef,undef,undef],
	['e2','c9',0,'two.sided',-1,0,0,1,0.94999999999999996,18,0.029523215949937898,'Wilcoxon rank sum test',2.5000000000005755,-0.5,6.2499999999990168,0.94999999999999996],
	['eflat','eflat',0,'two.sided',0,0,0,0,0.90000000000000002,18,'NaN','Wilcoxon rank sum test',undef,undef,undef,undef],
	['ezero','emix',0,'two.sided',0,0,0,0,0.98999999999999999,10,0.52052950299709311,'Wilcoxon rank sum test',undef,undef,undef,undef],
	['a9','a9',0,'two.sided',0.5,0,0,1,0.94999999999999996,26,0.20041107494054261,'Wilcoxon rank sum test',0,-0.8349609375001642,0.8349609375001642,0.94999999999999996],
	['b12','c12',0,'two.sided',-1,0,0,0,0.90000000000000002,81,0.59957823211697936,'Wilcoxon rank sum test',undef,undef,undef,undef],
	['a9','b9',1,'two.sided',0,0,0,0,0.98999999999999999,8,0.085830958444285677,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['b9','c9',1,'two.sided',0,0,0,1,0.94999999999999996,12,0.73016617433799147,'Wilcoxon signed rank test',-1.2067681407364712e-13,-1.0000000000000591,1.1249999999999334,0.94999999999999996],
	['a15','d15',1,'two.sided',0.5,0,0,0,0.90000000000000002,1,0.00080527623696681418,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['b15','c15',1,'two.sided',-1,0,0,0,0.98999999999999999,95.5,0.0069189672706997385,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['d12','b12',1,'two.sided',0,0,0,1,0.94999999999999996,75,0.0047417680384069794,'Wilcoxon signed rank test',2.2065969577593094,1.1259765624992475,3.0795898437506111,0.94999999999999996],
	['eflat','eflat',1,'two.sided',0,0,0,0,0.90000000000000002,0,'NaN','Wilcoxon signed rank test',undef,undef,undef,undef],
	['ezero','emix',1,'two.sided',0.5,0,0,0,0.98999999999999999,2,0.1307970618068586,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['a9','a9',1,'two.sided',-1,0,0,1,0.94999999999999996,45,0.0026997960632602069,'Wilcoxon signed rank test',0,'NaN','NaN',0],
	['b12','c12',1,'two.sided',0,0,0,0,0.90000000000000002,24,0.23549689144695612,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['a4','',0,'two.sided',0,0,0,0,0.98999999999999999,4,0.71500065468808915,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['a9','',0,'two.sided',0.5,0,0,1,0.94999999999999996,0,0.0076857940552132707,'Wilcoxon signed rank test',-0.60205078124962186,-1.2109374999999427,0.089843749999159145,0.94999999999999996],
	['a15','',0,'two.sided',-1,0,0,0,0.90000000000000002,108,0.006406490222167438,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['b9','',0,'two.sided',0,0,0,0,0.98999999999999999,8,0.59507649562394871,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['b15','',0,'two.sided',0,0,0,1,0.94999999999999996,50,0.75182963404584924,'Wilcoxon signed rank test',1.9809696469588483e-13,-0.62500000000070433,0.62500000000014,0.94999999999999996],
	['c9','',0,'two.sided',0.5,0,0,0,0.90000000000000002,12.5,0.22095972608332015,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['c15','',0,'two.sided',-1,0,0,0,0.98999999999999999,67,0.12496883110630064,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['d9','',0,'two.sided',0,0,0,1,0.94999999999999996,45,0.0076857940552133019,'Wilcoxon signed rank test',1.8007812500004099,0.9560546875002699,2.6757812499999689,0.94999999999999996],
	['d15','',0,'two.sided',0,0,0,0,0.90000000000000002,119,0.00080527623696680095,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['e1','',0,'two.sided',0.5,0,0,0,0.98999999999999999,1,0.31731050786291415,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['e2','',0,'two.sided',-1,0,0,1,0.94999999999999996,3,0.17971249487899987,'Wilcoxon signed rank test',2.875,1.5,4.25,0.59999999999999964],
	['eflat','',0,'two.sided',0,0,0,0,0.90000000000000002,21,0.014305878435429742,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['ezero','',0,'two.sided',0,0,0,0,0.98999999999999999,0,'NaN','Wilcoxon signed rank test',undef,undef,undef,undef],
	['emix','',0,'two.sided',0.5,0,0,1,0.94999999999999996,6.5,0.78252792474006738,'Wilcoxon signed rank test',0.49999999999943856,-0.50000000000010347,1.5000000000002109,0.89999999999999991],
	['a4','a9',0,'less',-1,1,undef,0,0.90000000000000002,29,0.96223776223776225,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a9','b9',0,'less',0,1,undef,0,0.98999999999999999,30,0.18663101604278076,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['b9','c9',0,'less',0,1,undef,1,0.94999999999999996,45.5,0.6792677910324969,'Wilcoxon rank sum exact test',0,'-Inf',1,0.97227478403948997],
	['c9','d9',0,'less',0.5,1,undef,0,0.90000000000000002,7,0.00082270670505964617,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a15','d15',0,'less',-1,1,undef,0,0.98999999999999999,108,0.43509722821767649,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['b15','c15',0,'less',0,1,undef,1,0.94999999999999996,137,0.84773447899373322,'Wilcoxon rank sum exact test',0.75,'-Inf',1.5,0.97307154601233958],
	['d12','b12',0,'less',0,1,undef,0,0.90000000000000002,130,0.99985207953978983,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['c12','a7',0,'less',0.5,1,undef,0,0.98999999999999999,39,0.40997856632531554,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['e1','a9',0,'less',-1,1,undef,1,0.94999999999999996,9,1,'Wilcoxon rank sum exact test',3.197265625,'-Inf','Inf',1],
	['e2','c9',0,'less',0,1,undef,0,0.90000000000000002,16,0.96363636363636362,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['eflat','eflat',0,'less',0,1,undef,0,0.98999999999999999,18,1,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['ezero','emix',0,'less',0.5,1,undef,1,0.94999999999999996,5,0.023809523809523808,'Wilcoxon rank sum exact test',0,'-Inf',0,0.97619047619047616],
	['a9','a9',0,'less',-1,1,undef,0,0.90000000000000002,68,0.99469354175236524,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['b12','c12',0,'less',0,1,undef,0,0.98999999999999999,53.5,0.14763497372193024,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a9','b9',1,'less',0,1,undef,1,0.94999999999999996,8,0.048828125,'Wilcoxon signed rank exact test',-0.5224609375,'-Inf',-0.017578125,0.951171875],
	['b9','c9',1,'less',0.5,1,undef,0,0.90000000000000002,16,0.240234375,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a15','d15',1,'less',-1,1,undef,0,0.98999999999999999,57,0.44519042968750006,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b15','c15',1,'less',0,1,undef,1,0.94999999999999996,76.5,0.831787109375,'Wilcoxon signed rank exact test',0.5,'-Inf',1.25,0.959869384765625],
	['d12','b12',1,'less',0,1,undef,0,0.90000000000000002,75,0.999267578125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['eflat','eflat',1,'less',0.5,1,undef,0,0.98999999999999999,0,0.015625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['ezero','emix',1,'less',-1,1,undef,1,0.94999999999999996,11,0.9375,'Wilcoxon signed rank exact test',-0.5,'-Inf',1,1],
	['a9','a9',1,'less',0,1,undef,0,0.90000000000000002,0,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b12','c12',1,'less',0,1,undef,0,0.98999999999999999,24,0.126953125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a4','',0,'less',0.5,1,undef,1,0.94999999999999996,3,0.3125,'Wilcoxon signed rank exact test',-0.21044921875,'-Inf','Inf',1],
	['a9','',0,'less',-1,1,undef,0,0.90000000000000002,36,0.951171875,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a15','',0,'less',0,1,undef,0,0.98999999999999999,66,0.64013671875,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b9','',0,'less',0,1,undef,1,0.94999999999999996,17,0.40625,'Wilcoxon signed rank exact test',0,'-Inf',0.25,0.970703125],
	['b15','',0,'less',0.5,1,undef,0,0.90000000000000002,31.5,0.05694580078125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['c9','',0,'less',-1,1,undef,0,0.98999999999999999,29.5,0.96875,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['c15','',0,'less',0,1,undef,1,0.94999999999999996,41,0.156494140625,'Wilcoxon signed rank exact test',-0.5,'-Inf',0,0.950836181640625],
	['d9','',0,'less',0,1,undef,0,0.90000000000000002,45,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['d15','',0,'less',0.5,1,undef,0,0.98999999999999999,111,0.999237060546875,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['e1','',0,'less',-1,1,undef,1,0.94999999999999996,1,1,'Wilcoxon signed rank exact test',2.5,'-Inf','Inf',1],
	['e2','',0,'less',0,1,undef,0,0.90000000000000002,3,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['eflat','',0,'less',0,1,undef,0,0.98999999999999999,21,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['ezero','',0,'less',0.5,1,undef,1,0.94999999999999996,0,0.03125,'Wilcoxon signed rank exact test',0,'-Inf',0,0.96875],
	['emix','',0,'less',-1,1,undef,0,0.90000000000000002,14,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a4','a9',0,'less',0,0,undef,0,0.98999999999999999,21,0.6979020979020979,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a9','b9',0,'less',0,0,undef,1,0.94999999999999996,30,0.18663101604278076,'Wilcoxon rank sum exact test',-0.5556640625,'-Inf',0.1337890625,0.95559440559440556],
	['b9','c9',0,'less',0.5,0,undef,0,0.90000000000000002,38,0.42268613739201977,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['c9','d9',0,'less',-1,0,undef,0,0.98999999999999999,23,0.063903743315508021,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a15','d15',0,'less',0,0,undef,1,0.94999999999999996,48,0.0032840262015535054,'Wilcoxon rank sum exact test',-1.0517578125,'-Inf',-0.4443359375,0.95123712008804684],
	['b15','c15',0,'less',0,0,undef,0,0.90000000000000002,137,0.84773447899373322,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['d12','b12',0,'less',0.5,0,undef,0,0.98999999999999999,119,0.99763290283548733,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['c12','a7',0,'less',-1,0,undef,1,0.94999999999999996,65,0.97743510359609431,'Wilcoxon rank sum exact test',0.169921875,'-Inf',1.845703125,0.9558029689608637],
	['e1','a9',0,'less',0,0,undef,0,0.90000000000000002,9,1,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['e2','c9',0,'less',0,0,undef,0,0.98999999999999999,16,0.96363636363636362,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['eflat','eflat',0,'less',0.5,0,undef,1,0.94999999999999996,0,0.0010822510822510823,'Wilcoxon rank sum exact test',0,'-Inf',0,1],
	['ezero','emix',0,'less',-1,0,undef,0,0.90000000000000002,17.5,0.94047619047619047,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a9','a9',0,'less',0,0,undef,0,0.98999999999999999,40.5,0.53463595228301108,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['b12','c12',0,'less',0,0,undef,1,0.94999999999999996,53.5,0.14763497372193024,'Wilcoxon rank sum exact test',-0.75,'-Inf',0.5,0.97872201159992245],
	['a9','b9',1,'less',0.5,0,undef,0,0.90000000000000002,2,0.005859375,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b9','c9',1,'less',-1,0,undef,0,0.98999999999999999,38,0.970703125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a15','d15',1,'less',0,0,undef,1,0.94999999999999996,13,0.0026855468750000009,'Wilcoxon signed rank exact test',-1.134033203125,'-Inf',-0.5546875,0.95269775390625],
	['b15','c15',1,'less',0,0,undef,0,0.90000000000000002,76.5,0.831787109375,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['d12','b12',1,'less',0.5,0,undef,0,0.98999999999999999,71,0.99658203125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['eflat','eflat',1,'less',-1,0,undef,1,0.94999999999999996,21,1,'Wilcoxon signed rank exact test',0,'-Inf',0,0.984375],
	['ezero','emix',1,'less',0,0,undef,0,0.90000000000000002,3.5,0.375,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a9','a9',1,'less',0,0,undef,0,0.98999999999999999,0,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b12','c12',1,'less',0.5,0,undef,1,0.94999999999999996,10,0.02734375,'Wilcoxon signed rank exact test',-0.6875,'-Inf',0.5,0.990234375],
	['a4','',0,'less',-1,0,undef,0,0.90000000000000002,8,0.875,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a9','',0,'less',0,0,undef,0,0.98999999999999999,7,0.037109375,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a15','',0,'less',0,0,undef,1,0.94999999999999996,66,0.64013671875,'Wilcoxon signed rank exact test',0.205078125,'-Inf',0.69677734375,0.95269775390625],
	['b9','',0,'less',0.5,0,undef,0,0.90000000000000002,2,0.0078125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b15','',0,'less',-1,0,undef,0,0.98999999999999999,109,0.999267578125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['c9','',0,'less',0,0,undef,1,0.94999999999999996,20,0.5,'Wilcoxon signed rank exact test',0,'-Inf',0.5,0.95703125],
	['c15','',0,'less',0,0,undef,0,0.90000000000000002,41,0.156494140625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['d9','',0,'less',0.5,0,undef,0,0.98999999999999999,44,0.998046875,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['d15','',0,'less',-1,0,undef,1,0.94999999999999996,120,1,'Wilcoxon signed rank exact test',1.291748046875,'-Inf',1.607421875,0.95269775390625],
	['e1','',0,'less',0,0,undef,0,0.90000000000000002,1,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['e2','',0,'less',0,0,undef,0,0.98999999999999999,3,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['eflat','',0,'less',0.5,0,undef,1,0.94999999999999996,21,1,'Wilcoxon signed rank exact test',3,'-Inf',3,0.984375],
	['ezero','',0,'less',-1,0,undef,0,0.90000000000000002,15,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['emix','',0,'less',0,0,undef,0,0.98999999999999999,8.5,0.875,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a4','a9',0,'less',0,1,1,1,0.94999999999999996,21,0.6979020979020979,'Wilcoxon rank sum exact test',0.45458984375,'-Inf',1.818359375,0.96223776223776225],
	['a9','b9',0,'less',0.5,1,1,0,0.90000000000000002,10,0.0025503907856849035,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['b9','c9',0,'less',-1,1,1,0,0.98999999999999999,57.5,0.93745372274784045,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['c9','d9',0,'less',0,1,1,1,0.94999999999999996,15,0.011188811188811189,'Wilcoxon rank sum exact test',-1.986328125,'-Inf',-0.986328125,0.9561291649526944],
	['a15','d15',0,'less',0,1,1,0,0.90000000000000002,48,0.0032840262015535054,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['b15','c15',0,'less',0.5,1,1,0,0.98999999999999999,119.5,0.61749828130310491,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['d12','b12',0,'less',-1,1,1,1,0.94999999999999996,138,0.99999186437468846,'Wilcoxon rank sum exact test',2.27978515625,'-Inf',3.1708984375,0.9514950320913439],
	['c12','a7',0,'less',0,1,1,0,0.90000000000000002,48,0.69760657299356987,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['e1','a9',0,'less',0,1,1,0,0.98999999999999999,9,1,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['e2','c9',0,'less',0.5,1,1,1,0.94999999999999996,15.5,0.94545454545454544,'Wilcoxon rank sum exact test',2.5,'-Inf',5.25,0.96363636363636362],
	['eflat','eflat',0,'less',-1,1,1,0,0.90000000000000002,36,1,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['ezero','emix',0,'less',0,1,1,0,0.98999999999999999,10,0.3611111111111111,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a9','a9',0,'less',0,1,1,1,0.94999999999999996,40.5,0.53463595228301108,'Wilcoxon rank sum exact test',0,'-Inf',0.7392578125,0.9530440148087207],
	['b12','c12',0,'less',0.5,1,1,0,0.90000000000000002,37.5,0.02127798840007751,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a9','b9',1,'less',-1,1,1,0,0.98999999999999999,39,0.98046875,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b9','c9',1,'less',0,1,1,1,0.94999999999999996,20,0.5,'Wilcoxon signed rank exact test',0,'-Inf',1,0.962890625],
	['a15','d15',1,'less',0,1,1,0,0.90000000000000002,13,0.0026855468750000009,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b15','c15',1,'less',0.5,1,1,0,0.98999999999999999,60,0.5167236328125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['d12','b12',1,'less',-1,1,1,1,0.94999999999999996,78,1,'Wilcoxon signed rank exact test',2.22021484375,'-Inf',3.04345703125,0.953857421875],
	['eflat','eflat',1,'less',0,1,1,0,0.90000000000000002,0,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['ezero','emix',1,'less',0,1,1,0,0.98999999999999999,3.5,0.375,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a9','a9',1,'less',0.5,1,1,1,0.94999999999999996,0,0.001953125,'Wilcoxon signed rank exact test',0,'-Inf',0,0.998046875],
	['b12','c12',1,'less',-1,1,1,0,0.90000000000000002,41,0.6123046875,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a4','',0,'less',0,1,1,0,0.98999999999999999,4,0.4375,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a9','',0,'less',0,1,1,1,0.94999999999999996,7,0.037109375,'Wilcoxon signed rank exact test',-0.60205078125,'-Inf',-0.1240234375,0.951171875],
	['a15','',0,'less',0.5,1,1,0,0.90000000000000002,44,0.19470214843750003,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b9','',0,'less',-1,1,1,0,0.98999999999999999,42,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b15','',0,'less',0,1,1,1,0.94999999999999996,62,0.5843505859375,'Wilcoxon signed rank exact test',0,'-Inf',0.5,0.96466064453125],
	['c9','',0,'less',0,1,1,0,0.90000000000000002,20,0.5,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['c15','',0,'less',0.5,1,1,0,0.98999999999999999,27,0.029144287109375,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['d9','',0,'less',-1,1,1,1,0.94999999999999996,45,1,'Wilcoxon signed rank exact test',1.80078125,'-Inf',2.41796875,0.951171875],
	['d15','',0,'less',0,1,1,0,0.90000000000000002,119,0.999969482421875,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['e1','',0,'less',0,1,1,0,0.98999999999999999,1,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['e2','',0,'less',0.5,1,1,1,0.94999999999999996,3,1,'Wilcoxon signed rank exact test',2.875,'-Inf','Inf',1],
	['eflat','',0,'less',-1,1,1,0,0.90000000000000002,21,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['ezero','',0,'less',0,1,1,0,0.98999999999999999,0,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['emix','',0,'less',0,1,1,1,0.94999999999999996,8.5,0.875,'Wilcoxon signed rank exact test',0.5,'-Inf',2,1],
	['a4','a9',0,'less',0.5,0,1,0,0.90000000000000002,17,0.46993006993006997,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a9','b9',0,'less',-1,0,1,0,0.98999999999999999,59,0.95113122171945708,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['b9','c9',0,'less',0,0,1,1,0.94999999999999996,45.5,0.6792677910324969,'Wilcoxon rank sum exact test',0,'-Inf',1,0.97227478403948997],
	['c9','d9',0,'less',0,0,1,0,0.90000000000000002,15,0.011188811188811189,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a15','d15',0,'less',0.5,0,1,0,0.98999999999999999,24,4.4894993163892768e-05,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['b15','c15',0,'less',-1,0,1,1,0.94999999999999996,168,0.99104783263682916,'Wilcoxon rank sum exact test',0.75,'-Inf',1.5,0.97307154601233958],
	['d12','b12',0,'less',0,0,1,0,0.90000000000000002,130,0.99985207953978983,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['c12','a7',0,'less',0,0,1,0,0.98999999999999999,48,0.69760657299356987,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['e1','a9',0,'less',0.5,0,1,1,0.94999999999999996,9,1,'Wilcoxon rank sum exact test',3.197265625,'-Inf','Inf',1],
	['e2','c9',0,'less',-1,0,1,0,0.90000000000000002,18,1,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['eflat','eflat',0,'less',0,0,1,0,0.98999999999999999,18,1,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['ezero','emix',0,'less',0,0,1,1,0.94999999999999996,10,0.3611111111111111,'Wilcoxon rank sum exact test',0,'-Inf',0,0.97619047619047616],
	['a9','a9',0,'less',0.5,0,1,0,0.90000000000000002,26,0.11120937885643768,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['b12','c12',0,'less',-1,0,1,0,0.98999999999999999,81,0.70263069142460721,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a9','b9',1,'less',0,0,1,1,0.94999999999999996,8,0.048828125,'Wilcoxon signed rank exact test',-0.5224609375,'-Inf',-0.017578125,0.951171875],
	['b9','c9',1,'less',0,0,1,0,0.90000000000000002,20,0.5,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a15','d15',1,'less',0.5,0,1,0,0.98999999999999999,1,6.1035156250000027e-05,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b15','c15',1,'less',-1,0,1,1,0.94999999999999996,106.5,0.997802734375,'Wilcoxon signed rank exact test',0.5,'-Inf',1.25,0.959869384765625],
	['d12','b12',1,'less',0,0,1,0,0.90000000000000002,75,0.999267578125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['eflat','eflat',1,'less',0,0,1,0,0.98999999999999999,0,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['ezero','emix',1,'less',0.5,0,1,1,0.94999999999999996,2,0.125,'Wilcoxon signed rank exact test',-0.5,'-Inf',1,1],
	['a9','a9',1,'less',-1,0,1,0,0.90000000000000002,45,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b12','c12',1,'less',0,0,1,0,0.98999999999999999,24,0.126953125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a4','',0,'less',0,0,1,1,0.94999999999999996,4,0.4375,'Wilcoxon signed rank exact test',-0.21044921875,'-Inf','Inf',1],
	['a9','',0,'less',0.5,0,1,0,0.90000000000000002,0,0.001953125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a15','',0,'less',-1,0,1,0,0.98999999999999999,108,0.998321533203125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b9','',0,'less',0,0,1,1,0.94999999999999996,17,0.40625,'Wilcoxon signed rank exact test',0,'-Inf',0.25,0.970703125],
	['b15','',0,'less',0,0,1,0,0.90000000000000002,62,0.5843505859375,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['c9','',0,'less',0.5,0,1,0,0.98999999999999999,12.5,0.150390625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['c15','',0,'less',-1,0,1,1,0.94999999999999996,81,0.890869140625,'Wilcoxon signed rank exact test',-0.5,'-Inf',0,0.950836181640625],
	['d9','',0,'less',0,0,1,0,0.90000000000000002,45,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['d15','',0,'less',0,0,1,0,0.98999999999999999,119,0.999969482421875,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['e1','',0,'less',0.5,0,1,1,0.94999999999999996,1,1,'Wilcoxon signed rank exact test',2.5,'-Inf','Inf',1],
	['e2','',0,'less',-1,0,1,0,0.90000000000000002,3,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['eflat','',0,'less',0,0,1,0,0.98999999999999999,21,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['ezero','',0,'less',0,0,1,1,0.94999999999999996,0,1,'Wilcoxon signed rank exact test',0,'-Inf',0,0.96875],
	['emix','',0,'less',0.5,0,1,0,0.90000000000000002,6.5,0.5,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a4','a9',0,'less',-1,1,0,0,0.98999999999999999,29,0.96200881071141553,'Wilcoxon rank sum test with continuity correction',undef,undef,undef,undef],
	['a9','b9',0,'less',0,1,0,1,0.94999999999999996,30,0.18787123910610518,'Wilcoxon rank sum test with continuity correction',-0.55566406250039169,'-Inf',0.13378906250002051,0.94999999999999996],
	['b9','c9',0,'less',0,1,0,0,0.90000000000000002,45.5,0.69071801074328076,'Wilcoxon rank sum test with continuity correction',undef,undef,undef,undef],
	['c9','d9',0,'less',0.5,1,0,0,0.98999999999999999,7,0.001691252358006663,'Wilcoxon rank sum test with continuity correction',undef,undef,undef,undef],
	['a15','d15',0,'less',-1,1,0,1,0.94999999999999996,108,0.43411299517621771,'Wilcoxon rank sum test with continuity correction',-1.0517578125002252,'-Inf',-0.44433593749967543,0.94999999999999996],
	['b15','c15',0,'less',0,1,0,0,0.90000000000000002,137,0.85248128770086962,'Wilcoxon rank sum test with continuity correction',undef,undef,undef,undef],
	['d12','b12',0,'less',0,1,0,0,0.98999999999999999,130,0.99963718026434434,'Wilcoxon rank sum test with continuity correction',undef,undef,undef,undef],
	['c12','a7',0,'less',0.5,1,0,1,0.94999999999999996,39,0.41544962144982805,'Wilcoxon rank sum test with continuity correction',0.16992187499965528,'-Inf',1.8457031249999685,0.94999999999999996],
	['e1','a9',0,'less',-1,1,0,0,0.90000000000000002,9,0.95913862385067028,'Wilcoxon rank sum test with continuity correction',undef,undef,undef,undef],
	['e2','c9',0,'less',0,1,0,0,0.98999999999999999,16,0.96513731540824355,'Wilcoxon rank sum test with continuity correction',undef,undef,undef,undef],
	['ezero','emix',0,'less',0.5,1,0,0,0.90000000000000002,5,0.058762434048319594,'Wilcoxon rank sum test with continuity correction',undef,undef,undef,undef],
	['a9','a9',0,'less',-1,1,0,0,0.98999999999999999,68,0.99329067103975122,'Wilcoxon rank sum test with continuity correction',undef,undef,undef,undef],
	['b12','c12',0,'less',0,1,0,1,0.94999999999999996,53.5,0.14760351975316588,'Wilcoxon rank sum test with continuity correction',-0.74999999999996247,'-Inf',0.49999999999951639,0.94999999999999996],
	['a9','b9',1,'less',0,1,0,0,0.90000000000000002,8,0.048600544153117355,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['b9','c9',1,'less',0.5,1,0,0,0.98999999999999999,16,0.23624880700034426,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['a15','d15',1,'less',-1,1,0,1,0.94999999999999996,57,0.44354377114474014,'Wilcoxon signed rank test with continuity correction',-1.1361067140523757,'-Inf',-0.55468750000050149,0.94999999999999996],
	['b15','c15',1,'less',0,1,0,0,0.90000000000000002,67.5,0.83514978776318749,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['d12','b12',1,'less',0,1,0,0,0.98999999999999999,75,0.99790370370805337,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['eflat','eflat',1,'less',0.5,1,0,1,0.94999999999999996,0,0.0098280786250849374,'Wilcoxon signed rank test with continuity correction',0,'-Inf','NaN',0],
	['ezero','emix',1,'less',-1,1,0,0,0.90000000000000002,8,0.90706163381706195,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['a9','a9',1,'less',0,1,0,0,0.98999999999999999,0,1,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['b12','c12',1,'less',0,1,0,1,0.94999999999999996,24,0.12573758120893555,'Wilcoxon signed rank test with continuity correction',-0.70304928468751926,'-Inf',0.49999999999956468,0.94999999999999996],
	['a4','',0,'less',0.5,1,0,0,0.90000000000000002,3,0.29194121038518261,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['a9','',0,'less',-1,1,0,0,0.98999999999999999,36,0.95139945584688268,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['a15','',0,'less',0,1,0,1,0.94999999999999996,66,0.64400142720573084,'Wilcoxon signed rank test with continuity correction',0.1973870985846666,'-Inf',0.69677734374985334,0.94999999999999996],
	['b9','',0,'less',0,1,0,0,0.90000000000000002,8,0.33534719050212103,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['b15','',0,'less',0.5,1,0,0,0.98999999999999999,26.5,0.053967373281347611,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['c9','',0,'less',-1,1,0,1,0.94999999999999996,13.5,0.96155939754564734,'Wilcoxon signed rank test with continuity correction',-3.5521469657121746e-13,'-Inf',0.50000000000077138,0.94999999999999996],
	['c15','',0,'less',0,1,0,0,0.90000000000000002,35,0.13568212563825008,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['d9','',0,'less',0,1,0,0,0.98999999999999999,45,0.99678302471051805,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['d15','',0,'less',0.5,1,0,1,0.94999999999999996,111,0.99827773795804176,'Wilcoxon signed rank test with continuity correction',1.2932737037706583,'-Inf',1.6074218749999485,0.94999999999999996],
	['e1','',0,'less',-1,1,0,0,0.90000000000000002,1,0.97724986805182079,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['e2','',0,'less',0,1,0,0,0.98999999999999999,3,0.96318086493984867,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['eflat','',0,'less',0,1,0,1,0.94999999999999996,21,0.99485801744579183,'Wilcoxon signed rank test with continuity correction',3,'-Inf','NaN',0],
	['ezero','',0,'less',0.5,1,0,0,0.90000000000000002,0,0.018444212853524947,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['emix','',0,'less',-1,1,0,0,0.98999999999999999,10,0.97857987666336443,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['a4','a9',0,'less',0,0,0,1,0.94999999999999996,21,0.67828557821818969,'Wilcoxon rank sum test',0.4690926266724697,'-Inf',1.7783203125003089,0.94999999999999996],
	['a9','b9',0,'less',0,0,0,0,0.90000000000000002,30,0.17617090211281128,'Wilcoxon rank sum test',undef,undef,undef,undef],
	['b9','c9',0,'less',0.5,0,0,0,0.98999999999999999,38,0.41187761174569437,'Wilcoxon rank sum test',undef,undef,undef,undef],
	['c9','d9',0,'less',-1,0,0,1,0.94999999999999996,23,0.060076213738443275,'Wilcoxon rank sum test',-1.9863281250008504,'-Inf',-0.98632812500013545,0.94999999999999996],
	['a15','d15',0,'less',0,0,0,0,0.90000000000000002,48,0.003732726410423666,'Wilcoxon rank sum test',undef,undef,undef,undef],
	['b15','c15',0,'less',0,0,0,0,0.98999999999999999,137,0.84759947198855334,'Wilcoxon rank sum test',undef,undef,undef,undef],
	['d12','b12',0,'less',0.5,0,0,1,0.94999999999999996,119,0.99668938909791072,'Wilcoxon rank sum test',2.2649590442709315,'-Inf',3.1708984374996145,0.94999999999999996],
	['c12','a7',0,'less',-1,0,0,0,0.90000000000000002,65,0.97527234562708653,'Wilcoxon rank sum test',undef,undef,undef,undef],
	['e1','a9',0,'less',0,0,0,0,0.98999999999999999,9,0.94140745640093093,'Wilcoxon rank sum test',undef,undef,undef,undef],
	['e2','c9',0,'less',0,0,0,1,0.94999999999999996,16,0.95475112619504521,'Wilcoxon rank sum test',2.5000000000005755,'-Inf',5.2500000000004388,0.94999999999999996],
	['eflat','eflat',0,'less',0.5,0,0,0,0.90000000000000002,0,0.00045555943857685563,'Wilcoxon rank sum test',undef,undef,undef,undef],
	['ezero','emix',0,'less',-1,0,0,0,0.98999999999999999,17.5,0.88124805907958581,'Wilcoxon rank sum test',undef,undef,undef,undef],
	['a9','a9',0,'less',0,0,0,1,0.94999999999999996,40.5,0.5,'Wilcoxon rank sum test',0,'-Inf',0.73925781249952938,0.94999999999999996],
	['b12','c12',0,'less',0,0,0,0,0.90000000000000002,53.5,0.1409985390766374,'Wilcoxon rank sum test',undef,undef,undef,undef],
	['a9','b9',1,'less',0.5,0,0,0,0.98999999999999999,2,0.0075779869404873045,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['b9','c9',1,'less',-1,0,0,1,0.94999999999999996,38,0.96767436269822538,'Wilcoxon signed rank test',-1.2067681407364712e-13,'-Inf',0.9999999999999396,0.94999999999999996],
	['a15','d15',1,'less',0,0,0,0,0.90000000000000002,13,0.0037991115410316218,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['b15','c15',1,'less',0,0,0,0,0.98999999999999999,67.5,0.82722986279700117,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['d12','b12',1,'less',0.5,0,0,1,0.94999999999999996,71,0.99396833829057263,'Wilcoxon signed rank test',2.2065969577593094,'-Inf',2.9707031250003926,0.94999999999999996],
	['eflat','eflat',1,'less',-1,0,0,0,0.90000000000000002,21,0.99284706078228513,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['ezero','emix',1,'less',0,0,0,0,0.98999999999999999,1.5,0.20710808912126252,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['a9','a9',1,'less',0,0,0,1,0.94999999999999996,0,'NaN','Wilcoxon signed rank test',0,'-Inf','NaN',0],
	['b12','c12',1,'less',0.5,0,0,0,0.90000000000000002,6,0.04624573505631497,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['a4','',0,'less',-1,0,0,0,0.98999999999999999,8,0.86333916085385098,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['a9','',0,'less',0,0,0,1,0.94999999999999996,7,0.033158015649465404,'Wilcoxon signed rank test',-0.60205078124962186,'-Inf',-0.1240234375007237,0.94999999999999996],
	['a15','',0,'less',0,0,0,0,0.90000000000000002,66,0.63336430458938964,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['b9','',0,'less',0.5,0,0,0,0.98999999999999999,2,0.0071819074277661276,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['b15','',0,'less',-1,0,0,1,0.94999999999999996,87,0.99817235062308851,'Wilcoxon signed rank test',1.9809696469588483e-13,'-Inf',0.50000000000042821,0.94999999999999996],
	['c9','',0,'less',0,0,0,0,0.90000000000000002,17,0.44261695723660083,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['c15','',0,'less',0,0,0,0,0.98999999999999999,35,0.12875899112453143,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['d9','',0,'less',0.5,0,0,1,0.94999999999999996,44,0.99456888764759221,'Wilcoxon signed rank test',1.8007812500004099,'-Inf',2.4179687499995581,0.94999999999999996],
	['d15','',0,'less',-1,0,0,0,0.90000000000000002,120,0.99967252082830715,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['e1','',0,'less',0,0,0,0,0.98999999999999999,1,0.84134474606854293,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['e2','',0,'less',0,0,0,1,0.94999999999999996,3,0.91014375256050006,'Wilcoxon signed rank test',2.875,'-Inf',2.8750000000002185,0.59999999999999964],
	['eflat','',0,'less',0.5,0,0,0,0.90000000000000002,21,0.99284706078228513,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['ezero','',0,'less',-1,0,0,0,0.98999999999999999,15,0.9873263406612659,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['emix','',0,'less',0,0,0,1,0.94999999999999996,4.5,0.79289191087873745,'Wilcoxon signed rank test',0.49999999999943856,'-Inf',1.0000000000003244,0.89999999999999991],
	['a4','a9',0,'greater',0,1,undef,0,0.90000000000000002,21,0.35524475524475524,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a9','b9',0,'greater',0.5,1,undef,0,0.98999999999999999,10,0.99786096256684487,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['b9','c9',0,'greater',-1,1,undef,1,0.94999999999999996,57.5,0.068881118881118919,'Wilcoxon rank sum exact test',0,-1,'Inf',0.9565816536404772],
	['c9','d9',0,'greater',0,1,undef,0,0.90000000000000002,15,0.99033319621554916,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a15','d15',0,'greater',0,1,undef,0,0.98999999999999999,48,0.99714824605241237,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['b15','c15',0,'greater',0.5,1,undef,1,0.94999999999999996,119.5,0.39057455276489728,'Wilcoxon rank sum exact test',0.75,-0.5,'Inf',0.95775103934101058],
	['d12','b12',0,'greater',-1,1,undef,0,0.90000000000000002,138,9.6148299136844528e-06,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['c12','a7',0,'greater',0,1,undef,0,0.98999999999999999,48,0.31529332380725572,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['e1','a9',0,'greater',0,1,undef,1,0.94999999999999996,9,0.10000000000000001,'Wilcoxon rank sum exact test',3.197265625,'-Inf','Inf',1],
	['e2','c9',0,'greater',0.5,1,undef,0,0.90000000000000002,15.5,0.090909090909090939,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['eflat','eflat',0,'greater',-1,1,undef,0,0.98999999999999999,36,0.0010822510822511289,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['ezero','emix',0,'greater',0,1,undef,1,0.94999999999999996,10,0.86111111111111116,'Wilcoxon rank sum exact test',0,-2,'Inf',0.97619047619047616],
	['a9','a9',0,'greater',0,1,undef,0,0.90000000000000002,40.5,0.53463595228301108,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['b12','c12',0,'greater',0.5,1,undef,0,0.98999999999999999,37.5,0.9801605380754661,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a9','b9',1,'greater',-1,1,undef,1,0.94999999999999996,39,0.02734375,'Wilcoxon signed rank exact test',-0.5224609375,-0.78173828125,'Inf',0.951171875],
	['b9','c9',1,'greater',0,1,undef,0,0.90000000000000002,20,0.546875,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a15','d15',1,'greater',0,1,undef,0,0.98999999999999999,13,0.99786376953125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b15','c15',1,'greater',0.5,1,undef,1,0.94999999999999996,60,0.4947509765625,'Wilcoxon signed rank exact test',0.5,-0.25,'Inf',0.951385498046875],
	['d12','b12',1,'greater',-1,1,undef,0,0.90000000000000002,78,0.00024414062500000016,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['eflat','eflat',1,'greater',0,1,undef,0,0.98999999999999999,0,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['ezero','emix',1,'greater',0,1,undef,1,0.94999999999999996,3.5,0.875,'Wilcoxon signed rank exact test',-0.5,-1.5,'Inf',0.96875],
	['a9','a9',1,'greater',0.5,1,undef,0,0.90000000000000002,0,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b12','c12',1,'greater',-1,1,undef,0,0.98999999999999999,41,0.4013671875,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a4','',0,'greater',0,1,undef,1,0.94999999999999996,4,0.6875,'Wilcoxon signed rank exact test',-0.21044921875,'-Inf','Inf',1],
	['a9','',0,'greater',0,1,undef,0,0.90000000000000002,7,0.97265625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a15','',0,'greater',0.5,1,undef,0,0.98999999999999999,44,0.8204345703125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b9','',0,'greater',-1,1,undef,1,0.94999999999999996,42,0.0078125,'Wilcoxon signed rank exact test',0,-0.5,'Inf',0.97265625],
	['b15','',0,'greater',0,1,undef,0,0.90000000000000002,62,0.42822265625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['c9','',0,'greater',0,1,undef,0,0.98999999999999999,20,0.6796875,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['c15','',0,'greater',0.5,1,undef,1,0.94999999999999996,27,0.971771240234375,'Wilcoxon signed rank exact test',-0.5,-1.5,'Inf',0.97528076171875],
	['d9','',0,'greater',-1,1,undef,0,0.90000000000000002,45,0.001953125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['d15','',0,'greater',0,1,undef,0,0.98999999999999999,119,6.1035156250000027e-05,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['e1','',0,'greater',0,1,undef,1,0.94999999999999996,1,0.5,'Wilcoxon signed rank exact test',2.5,'-Inf','Inf',1],
	['e2','',0,'greater',0.5,1,undef,0,0.90000000000000002,3,0.25,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['eflat','',0,'greater',-1,1,undef,0,0.98999999999999999,21,0.015625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['ezero','',0,'greater',0,1,undef,1,0.94999999999999996,0,1,'Wilcoxon signed rank exact test',0,0,'Inf',1],
	['emix','',0,'greater',0,1,undef,0,0.90000000000000002,8.5,0.375,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a4','a9',0,'greater',0.5,0,undef,0,0.98999999999999999,17,0.58741258741258739,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a9','b9',0,'greater',-1,0,undef,1,0.94999999999999996,59,0.053619909502262475,'Wilcoxon rank sum exact test',-0.5556640625,-1.06640625,'Inf',0.95505964623611683],
	['b9','c9',0,'greater',0,0,undef,0,0.90000000000000002,45.5,0.33928424516659805,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['c9','d9',0,'greater',0,0,undef,0,0.98999999999999999,15,0.99033319621554916,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a15','d15',0,'greater',0.5,0,undef,1,0.94999999999999996,24,0.99996439473761578,'Wilcoxon rank sum exact test',-1.0517578125,-1.6953125,'Inf',0.95123712008804684],
	['b15','c15',0,'greater',-1,0,undef,0,0.90000000000000002,168,0.0094575003519912215,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['d12','b12',0,'greater',0,0,undef,0,0.98999999999999999,130,0.00017047833039218752,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['c12','a7',0,'greater',0,0,undef,1,0.94999999999999996,48,0.31529332380725572,'Wilcoxon rank sum exact test',0.169921875,-0.4052734375,'Inf',0.9536199095022625],
	['e1','a9',0,'greater',0.5,0,undef,0,0.90000000000000002,9,0.10000000000000001,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['e2','c9',0,'greater',-1,0,undef,0,0.98999999999999999,18,0.018181818181818188,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['eflat','eflat',0,'greater',0,0,undef,1,0.94999999999999996,18,1,'Wilcoxon rank sum exact test',0,0,'Inf',1],
	['ezero','emix',0,'greater',0,0,undef,0,0.90000000000000002,10,0.86111111111111116,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a9','a9',0,'greater',0.5,0,undef,0,0.98999999999999999,26,0.90487453722747846,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['b12','c12',0,'greater',-1,0,undef,1,0.94999999999999996,81,0.30816380415922751,'Wilcoxon rank sum exact test',-0.75,-1.75,'Inf',0.96827143108607638],
	['a9','b9',1,'greater',0,0,undef,0,0.90000000000000002,8,0.962890625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b9','c9',1,'greater',0,0,undef,0,0.98999999999999999,20,0.546875,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a15','d15',1,'greater',0.5,0,undef,1,0.94999999999999996,1,0.999969482421875,'Wilcoxon signed rank exact test',-1.134033203125,-1.623046875,'Inf',0.95269775390625],
	['b15','c15',1,'greater',-1,0,undef,0,0.90000000000000002,106.5,0.0025634765625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['d12','b12',1,'greater',0,0,undef,0,0.98999999999999999,75,0.0012207031250000009,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['eflat','eflat',1,'greater',0,0,undef,1,0.94999999999999996,0,1,'Wilcoxon signed rank exact test',0,0,'Inf',1],
	['ezero','emix',1,'greater',0.5,0,undef,0,0.90000000000000002,2,0.96875,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a9','a9',1,'greater',-1,0,undef,0,0.98999999999999999,45,0.001953125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b12','c12',1,'greater',0,0,undef,1,0.94999999999999996,24,0.880859375,'Wilcoxon signed rank exact test',-0.6875,-1.875,'Inf',0.957763671875],
	['a4','',0,'greater',0,0,undef,0,0.90000000000000002,4,0.6875,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a9','',0,'greater',0.5,0,undef,0,0.98999999999999999,0,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a15','',0,'greater',-1,0,undef,1,0.94999999999999996,108,0.0021362304687500009,'Wilcoxon signed rank exact test',0.205078125,-0.45654296875,'Inf',0.95269775390625],
	['b9','',0,'greater',0,0,undef,0,0.90000000000000002,17,0.65625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b15','',0,'greater',0,0,undef,0,0.98999999999999999,62,0.42822265625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['c9','',0,'greater',0.5,0,undef,1,0.94999999999999996,12.5,0.908203125,'Wilcoxon signed rank exact test',0,-1,'Inf',0.990234375],
	['c15','',0,'greater',-1,0,undef,0,0.90000000000000002,81,0.1099853515625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['d9','',0,'greater',0,0,undef,0,0.98999999999999999,45,0.001953125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['d15','',0,'greater',0,0,undef,1,0.94999999999999996,119,6.1035156250000027e-05,'Wilcoxon signed rank exact test',1.291748046875,0.9111328125,'Inf',0.95269775390625],
	['e1','',0,'greater',0.5,0,undef,0,0.90000000000000002,1,0.5,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['e2','',0,'greater',-1,0,undef,0,0.98999999999999999,3,0.25,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['eflat','',0,'greater',0,0,undef,1,0.94999999999999996,21,0.015625,'Wilcoxon signed rank exact test',3,3,'Inf',1],
	['ezero','',0,'greater',0,0,undef,0,0.90000000000000002,0,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['emix','',0,'greater',0.5,0,undef,0,0.98999999999999999,6.5,0.6875,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a4','a9',0,'greater',-1,1,1,1,0.94999999999999996,29,0.053146853146853149,'Wilcoxon rank sum exact test',0.45458984375,-1.2919921875,'Inf',0.96223776223776225],
	['a9','b9',0,'greater',0,1,1,0,0.90000000000000002,30,0.82498971616618677,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['b9','c9',0,'greater',0,1,1,0,0.98999999999999999,45.5,0.33928424516659805,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['c9','d9',0,'greater',0.5,1,1,1,0.94999999999999996,7,0.99932126696832579,'Wilcoxon rank sum exact test',-1.986328125,-2.9892578125,'Inf',0.96386260798025503],
	['a15','d15',0,'greater',-1,1,1,0,0.90000000000000002,108,0.58093261160957188,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['b15','c15',0,'greater',0,1,1,0,0.98999999999999999,137,0.1572102493644818,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['d12','b12',0,'greater',0,1,1,1,0.94999999999999996,130,0.00017047833039218752,'Wilcoxon rank sum exact test',2.27978515625,1.416015625,'Inf',0.95136190367715467],
	['c12','a7',0,'greater',0.5,1,1,0,0.90000000000000002,39,0.60560053981106621,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['e1','a9',0,'greater',-1,1,1,0,0.98999999999999999,9,0.10000000000000001,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['e2','c9',0,'greater',0,1,1,1,0.94999999999999996,16,0.072727272727272751,'Wilcoxon rank sum exact test',2.5,-0.5,'Inf',1],
	['eflat','eflat',0,'greater',0,1,1,0,0.90000000000000002,18,1,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['ezero','emix',0,'greater',0.5,1,1,0,0.98999999999999999,5,0.98015873015873012,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a9','a9',0,'greater',-1,1,1,1,0.94999999999999996,68,0.0070958453311394491,'Wilcoxon rank sum exact test',0,-0.7392578125,'Inf',0.9530440148087207],
	['b12','c12',0,'greater',0,1,1,0,0.90000000000000002,53.5,0.85959759718004436,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a9','b9',1,'greater',0,1,1,0,0.98999999999999999,8,0.962890625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b9','c9',1,'greater',0.5,1,1,1,0.94999999999999996,16,0.771484375,'Wilcoxon signed rank exact test',0,-0.625,'Inf',0.96484375],
	['a15','d15',1,'greater',-1,1,1,0,0.90000000000000002,57,0.5765380859375,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b15','c15',1,'greater',0,1,1,0,0.98999999999999999,76.5,0.17626953125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['d12','b12',1,'greater',0,1,1,1,0.94999999999999996,75,0.0012207031250000009,'Wilcoxon signed rank exact test',2.22021484375,1.27001953125,'Inf',0.953857421875],
	['eflat','eflat',1,'greater',0.5,1,1,0,0.90000000000000002,0,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['ezero','emix',1,'greater',-1,1,1,0,0.98999999999999999,11,0.25,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a9','a9',1,'greater',0,1,1,1,0.94999999999999996,0,1,'Wilcoxon signed rank exact test',0,0,'Inf',1],
	['b12','c12',1,'greater',0,1,1,0,0.90000000000000002,24,0.880859375,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a4','',0,'greater',0.5,1,1,0,0.98999999999999999,3,0.8125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a9','',0,'greater',-1,1,1,1,0.94999999999999996,36,0.064453125,'Wilcoxon signed rank exact test',-0.60205078125,-1.12646484375,'Inf',0.951171875],
	['a15','',0,'greater',0,1,1,0,0.90000000000000002,66,0.38076782226562506,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b9','',0,'greater',0,1,1,0,0.98999999999999999,17,0.65625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b15','',0,'greater',0.5,1,1,1,0.94999999999999996,31.5,0.94549560546875,'Wilcoxon signed rank exact test',0,-0.5,'Inf',0.9627685546875],
	['c9','',0,'greater',-1,1,1,0,0.90000000000000002,29.5,0.09375,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['c15','',0,'greater',0,1,1,0,0.98999999999999999,41,0.869140625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['d9','',0,'greater',0,1,1,1,0.94999999999999996,45,0.001953125,'Wilcoxon signed rank exact test',1.80078125,1.130859375,'Inf',0.951171875],
	['d15','',0,'greater',0.5,1,1,0,0.90000000000000002,111,0.0010070800781250004,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['e1','',0,'greater',-1,1,1,0,0.98999999999999999,1,0.5,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['e2','',0,'greater',0,1,1,1,0.94999999999999996,3,0.25,'Wilcoxon signed rank exact test',2.875,'-Inf','Inf',1],
	['eflat','',0,'greater',0,1,1,0,0.90000000000000002,21,0.015625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['ezero','',0,'greater',0.5,1,1,0,0.98999999999999999,0,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['emix','',0,'greater',-1,1,1,1,0.94999999999999996,14,0.0625,'Wilcoxon signed rank exact test',0.5,-0.5,'Inf',0.96875],
	['a4','a9',0,'greater',0,0,1,0,0.90000000000000002,21,0.35524475524475524,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a9','b9',0,'greater',0,0,1,0,0.98999999999999999,30,0.82498971616618677,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['b9','c9',0,'greater',0.5,0,1,1,0.94999999999999996,38,0.59537227478403953,'Wilcoxon rank sum exact test',0,-1,'Inf',0.9565816536404772],
	['c9','d9',0,'greater',-1,0,1,0,0.90000000000000002,23,0.94148498560263261,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a15','d15',0,'greater',0,0,1,0,0.98999999999999999,48,0.99714824605241237,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['b15','c15',0,'greater',0,0,1,1,0.94999999999999996,137,0.1572102493644818,'Wilcoxon rank sum exact test',0.75,-0.5,'Inf',0.95775103934101058],
	['d12','b12',0,'greater',0.5,0,1,0,0.90000000000000002,119,0.0026259579698804103,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['c12','a7',0,'greater',-1,0,1,0,0.98999999999999999,65,0.025204413749305377,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['e1','a9',0,'greater',0,0,1,1,0.94999999999999996,9,0.10000000000000001,'Wilcoxon rank sum exact test',3.197265625,'-Inf','Inf',1],
	['e2','c9',0,'greater',0,0,1,0,0.90000000000000002,16,0.072727272727272751,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['eflat','eflat',0,'greater',0.5,0,1,0,0.98999999999999999,0,1,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['ezero','emix',0,'greater',-1,0,1,1,0.94999999999999996,17.5,0.08333333333333337,'Wilcoxon rank sum exact test',0,-2,'Inf',0.97619047619047616],
	['a9','a9',0,'greater',0,0,1,0,0.90000000000000002,40.5,0.53463595228301108,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['b12','c12',0,'greater',0,0,1,0,0.98999999999999999,53.5,0.85959759718004436,'Wilcoxon rank sum exact test',undef,undef,undef,undef],
	['a9','b9',1,'greater',0.5,0,1,1,0.94999999999999996,2,0.99609375,'Wilcoxon signed rank exact test',-0.5224609375,-0.78173828125,'Inf',0.951171875],
	['b9','c9',1,'greater',-1,0,1,0,0.90000000000000002,38,0.03515625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a15','d15',1,'greater',0,0,1,0,0.98999999999999999,13,0.99786376953125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b15','c15',1,'greater',0,0,1,1,0.94999999999999996,76.5,0.17626953125,'Wilcoxon signed rank exact test',0.5,-0.25,'Inf',0.951385498046875],
	['d12','b12',1,'greater',0.5,0,1,0,0.90000000000000002,71,0.0046386718750000035,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['eflat','eflat',1,'greater',-1,0,1,0,0.98999999999999999,21,0.015625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['ezero','emix',1,'greater',0,0,1,1,0.94999999999999996,3.5,0.875,'Wilcoxon signed rank exact test',-0.5,-1.5,'Inf',0.96875],
	['a9','a9',1,'greater',0,0,1,0,0.90000000000000002,0,1,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b12','c12',1,'greater',0.5,0,1,0,0.98999999999999999,10,0.9765625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a4','',0,'greater',-1,0,1,1,0.94999999999999996,8,0.1875,'Wilcoxon signed rank exact test',-0.21044921875,'-Inf','Inf',1],
	['a9','',0,'greater',0,0,1,0,0.90000000000000002,7,0.97265625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a15','',0,'greater',0,0,1,0,0.98999999999999999,66,0.38076782226562506,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['b9','',0,'greater',0.5,0,1,1,0.94999999999999996,2,0.998046875,'Wilcoxon signed rank exact test',0,-0.5,'Inf',0.97265625],
	['b15','',0,'greater',-1,0,1,0,0.90000000000000002,109,0.0010986328125,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['c9','',0,'greater',0,0,1,0,0.98999999999999999,20,0.6796875,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['c15','',0,'greater',0,0,1,1,0.94999999999999996,41,0.869140625,'Wilcoxon signed rank exact test',-0.5,-1.5,'Inf',0.97528076171875],
	['d9','',0,'greater',0.5,0,1,0,0.90000000000000002,44,0.00390625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['d15','',0,'greater',-1,0,1,0,0.98999999999999999,120,3.0517578125000014e-05,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['e1','',0,'greater',0,0,1,1,0.94999999999999996,1,0.5,'Wilcoxon signed rank exact test',2.5,'-Inf','Inf',1],
	['e2','',0,'greater',0,0,1,0,0.90000000000000002,3,0.25,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['eflat','',0,'greater',0.5,0,1,0,0.98999999999999999,21,0.015625,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['ezero','',0,'greater',-1,0,1,1,0.94999999999999996,15,0.03125,'Wilcoxon signed rank exact test',0,0,'Inf',1],
	['emix','',0,'greater',0,0,1,0,0.90000000000000002,8.5,0.375,'Wilcoxon signed rank exact test',undef,undef,undef,undef],
	['a4','a9',0,'greater',0,1,0,0,0.98999999999999999,21,0.34983781281735243,'Wilcoxon rank sum test with continuity correction',undef,undef,undef,undef],
	['a9','b9',0,'greater',0.5,1,0,1,0.94999999999999996,10,0.99698256986549882,'Wilcoxon rank sum test with continuity correction',-0.55566406250039169,-1.0664062499997824,'Inf',0.94999999999999996],
	['b9','c9',0,'greater',-1,1,0,0,0.90000000000000002,57.5,0.069846568709106396,'Wilcoxon rank sum test with continuity correction',undef,undef,undef,undef],
	['c9','d9',0,'greater',0,1,0,0,0.98999999999999999,15,0.9895281890435369,'Wilcoxon rank sum test with continuity correction',undef,undef,undef,undef],
	['a15','d15',0,'greater',0,1,0,1,0.94999999999999996,48,0.99649190038288016,'Wilcoxon rank sum test with continuity correction',-1.0517578125002252,-1.6953125000000271,'Inf',0.94999999999999996],
	['b15','c15',0,'greater',0.5,1,0,0,0.90000000000000002,119.5,0.39290240866876536,'Wilcoxon rank sum test with continuity correction',undef,undef,undef,undef],
	['d12','b12',0,'greater',-1,1,0,0,0.98999999999999999,138,7.7128875130304714e-05,'Wilcoxon rank sum test with continuity correction',undef,undef,undef,undef],
	['c12','a7',0,'greater',0,1,0,1,0.94999999999999996,48,0.31924664319376683,'Wilcoxon rank sum test with continuity correction',0.16992187499965528,-0.40527343750039968,'Inf',0.94999999999999996],
	['e1','a9',0,'greater',0,1,0,0,0.90000000000000002,9,0.081867177162296065,'Wilcoxon rank sum test with continuity correction',undef,undef,undef,undef],
	['e2','c9',0,'greater',0.5,1,0,0,0.98999999999999999,15.5,0.072912706991974136,'Wilcoxon rank sum test with continuity correction',undef,undef,undef,undef],
	['ezero','emix',0,'greater',0,1,0,0,0.90000000000000002,10,0.77965699175566106,'Wilcoxon rank sum test with continuity correction',undef,undef,undef,undef],
	['a9','a9',0,'greater',0,1,0,0,0.98999999999999999,40.5,0.5176903023184769,'Wilcoxon rank sum test with continuity correction',undef,undef,undef,undef],
	['b12','c12',0,'greater',0.5,1,0,1,0.94999999999999996,37.5,0.98008100652014196,'Wilcoxon rank sum test with continuity correction',-0.74999999999996247,-1.7499999999999118,'Inf',0.94999999999999996],
	['a9','b9',1,'greater',-1,1,0,0,0.90000000000000002,39,0.029012009973110719,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['b9','c9',1,'greater',0,1,0,0,0.98999999999999999,12,0.66681329890138907,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['a15','d15',1,'greater',0,1,0,1,0.94999999999999996,13,0.99651022809342971,'Wilcoxon signed rank test with continuity correction',-1.1361067140523757,-1.6230468749999178,'Inf',0.94999999999999996],
	['b15','c15',1,'greater',0.5,1,0,0,0.90000000000000002,52,0.525064773481972,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['d12','b12',1,'greater',-1,1,0,0,0.98999999999999999,78,0.0012630871342510846,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['eflat','eflat',1,'greater',0,1,0,1,0.94999999999999996,0,1,'Wilcoxon signed rank test with continuity correction',0,'NaN','Inf',0],
	['ezero','emix',1,'greater',0,1,0,0,0.90000000000000002,1.5,0.86184854133125832,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['a9','a9',1,'greater',0.5,1,0,0,0.98999999999999999,0,0.99891769951860676,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['b12','c12',1,'greater',-1,1,0,1,0.94999999999999996,29,0.45914108051373514,'Wilcoxon signed rank test with continuity correction',-0.70304928468751926,-1.8750000000005684,'Inf',0.94999999999999996],
	['a4','',0,'greater',0,1,0,0,0.90000000000000002,4,0.70805878961481739,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['a9','',0,'greater',0,1,0,0,0.98999999999999999,7,0.97098799002688929,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['a15','',0,'greater',0.5,1,0,1,0.94999999999999996,44,0.82565596122947338,'Wilcoxon signed rank test with continuity correction',0.1973870985846666,-0.45654296874977174,'Inf',0.94999999999999996],
	['b9','',0,'greater',-1,1,0,0,0.90000000000000002,28,0.010651588089351269,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['b15','',0,'greater',0,1,0,0,0.98999999999999999,50,0.38932016869042985,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['c9','',0,'greater',0,1,0,1,0.94999999999999996,17,0.58570346239067672,'Wilcoxon signed rank test with continuity correction',-3.5521469657121746e-13,-1.0000000000004281,'Inf',0.94999999999999996],
	['c15','',0,'greater',0.5,1,0,0,0.90000000000000002,27,0.97307911881920384,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['d9','',0,'greater',-1,1,0,0,0.98999999999999999,45,0.004575844426325036,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['d15','',0,'greater',0,1,0,1,0.94999999999999996,119,0.00044595068852956233,'Wilcoxon signed rank test with continuity correction',1.2932737037706583,0.91113281250017431,'Inf',0.94999999999999996],
	['e1','',0,'greater',0,1,0,0,0.90000000000000002,1,0.5,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['e2','',0,'greater',0.5,1,0,0,0.98999999999999999,3,0.18554668476134878,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['eflat','',0,'greater',-1,1,0,1,0.94999999999999996,21,0.0098280786250849374,'Wilcoxon signed rank test with continuity correction',3,'NaN','Inf',0],
	['ezero','',0,'greater',0,1,0,0,0.90000000000000002,0,1,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['emix','',0,'greater',0,1,0,0,0.98999999999999999,4.5,0.29310684053656999,'Wilcoxon signed rank test with continuity correction',undef,undef,undef,undef],
	['a4','a9',0,'greater',0.5,0,0,1,0.94999999999999996,17,0.56131472196792831,'Wilcoxon rank sum test',0.4690926266724697,-0.76660156250023948,'Inf',0.94999999999999996],
	['a9','b9',0,'greater',-1,0,0,0,0.90000000000000002,59,0.050640891126155274,'Wilcoxon rank sum test',undef,undef,undef,undef],
	['b9','c9',0,'greater',0,0,0,0,0.98999999999999999,45.5,0.32540969421510701,'Wilcoxon rank sum test',undef,undef,undef,undef],
	['c9','d9',0,'greater',0,0,0,1,0.94999999999999996,15,0.98823124134228491,'Wilcoxon rank sum test',-1.9863281250008504,-2.9892578125006182,'Inf',0.94999999999999996],
	['a15','d15',0,'greater',0.5,0,0,0,0.90000000000000002,24,0.9998791080130629,'Wilcoxon rank sum test',undef,undef,undef,undef],
	['b15','c15',0,'greater',-1,0,0,0,0.98999999999999999,168,0.01004563067137353,'Wilcoxon rank sum test',undef,undef,undef,undef],
	['d12','b12',0,'greater',0,0,0,1,0.94999999999999996,130,0.00040286678979670795,'Wilcoxon rank sum test',2.2649590442709315,1.4160156249994145,'Inf',0.94999999999999996],
	['c12','a7',0,'greater',0,0,0,0,0.90000000000000002,48,0.3041449077825914,'Wilcoxon rank sum test',undef,undef,undef,undef],
	['e1','a9',0,'greater',0.5,0,0,0,0.98999999999999999,9,0.058592543599069014,'Wilcoxon rank sum test',undef,undef,undef,undef],
	['e2','c9',0,'greater',-1,0,0,1,0.94999999999999996,18,0.014761607974968959,'Wilcoxon rank sum test',2.5000000000005755,0.49999999999972888,'Inf',0.94999999999999996],
	['eflat','eflat',0,'greater',0,0,0,0,0.90000000000000002,18,'NaN','Wilcoxon rank sum test',undef,undef,undef,undef],
	['ezero','emix',0,'greater',0,0,0,0,0.98999999999999999,10,0.73973524850145345,'Wilcoxon rank sum test',undef,undef,undef,undef],
	['a9','a9',0,'greater',0.5,0,0,1,0.94999999999999996,26,0.89979446252972872,'Wilcoxon rank sum test',0,-0.73925781249952938,'Inf',0.94999999999999996],
	['b12','c12',0,'greater',-1,0,0,0,0.90000000000000002,81,0.29978911605848968,'Wilcoxon rank sum test',undef,undef,undef,undef],
	['a9','b9',1,'greater',0,0,0,0,0.98999999999999999,8,0.95708452077785711,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['b9','c9',1,'greater',0,0,0,1,0.94999999999999996,12,0.63491691283100427,'Wilcoxon signed rank test',-1.2067681407364712e-13,-0.62500000000036748,'Inf',0.94999999999999996],
	['a15','d15',1,'greater',0.5,0,0,0,0.90000000000000002,1,0.9995973618815166,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['b15','c15',1,'greater',-1,0,0,0,0.98999999999999999,95.5,0.0034594836353498814,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['d12','b12',1,'greater',0,0,0,1,0.94999999999999996,75,0.0023708840192034879,'Wilcoxon signed rank test',2.2065969577593094,1.300292968749843,'Inf',0.94999999999999996],
	['eflat','eflat',1,'greater',0,0,0,0,0.90000000000000002,0,'NaN','Wilcoxon signed rank test',undef,undef,undef,undef],
	['ezero','emix',1,'greater',0.5,0,0,0,0.98999999999999999,2,0.93460146909657071,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['a9','a9',1,'greater',-1,0,0,1,0.94999999999999996,45,0.0013498980316300946,'Wilcoxon signed rank test',0,'NaN','Inf',0],
	['b12','c12',1,'greater',0,0,0,0,0.90000000000000002,24,0.88225155427652191,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['a4','',0,'greater',0,0,0,0,0.98999999999999999,4,0.64249967265595542,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['a9','',0,'greater',0.5,0,0,1,0.94999999999999996,0,0.99615710297239335,'Wilcoxon signed rank test',-0.60205078124962186,-1.1264648437499496,'Inf',0.94999999999999996],
	['a15','',0,'greater',-1,0,0,0,0.90000000000000002,108,0.0032032451110836887,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['b9','',0,'greater',0,0,0,0,0.98999999999999999,8,0.70246175218802565,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['b15','',0,'greater',0,0,0,1,0.94999999999999996,50,0.37591481702292462,'Wilcoxon signed rank test',1.9809696469588483e-13,-0.50000000000013634,'Inf',0.94999999999999996],
	['c9','',0,'greater',0.5,0,0,0,0.90000000000000002,12.5,0.88952013695833987,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['c15','',0,'greater',-1,0,0,0,0.98999999999999999,67,0.062484415553150298,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['d9','',0,'greater',0,0,0,1,0.94999999999999996,45,0.0038428970276066354,'Wilcoxon signed rank test',1.8007812500004099,1.1308593750006839,'Inf',0.94999999999999996],
	['d15','',0,'greater',0,0,0,0,0.90000000000000002,119,0.00040263811848340709,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['e1','',0,'greater',0.5,0,0,0,0.98999999999999999,1,0.15865525393145705,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['e2','',0,'greater',-1,0,0,1,0.94999999999999996,3,0.089856247439499923,'Wilcoxon signed rank test',2.875,1.5,'Inf',0.79999999999999982],
	['eflat','',0,'greater',0,0,0,0,0.90000000000000002,21,0.007152939217714825,'Wilcoxon signed rank test',undef,undef,undef,undef],
	['ezero','',0,'greater',0,0,0,0,0.98999999999999999,0,'NaN','Wilcoxon signed rank test',undef,undef,undef,undef],
	['emix','',0,'greater',0.5,0,0,1,0.94999999999999996,6.5,0.60873603762996631,'Wilcoxon signed rank test',0.49999999999943856,-0.50000000000010347,'Inf',0.94999999999999996], 
);
# END GENERATED CORPUS

foreach my $c (@CORPUS) {
	my ($xk, $yk, $paired, $alt, $mu, $correct, $exact, $ci, $clevel,
	    $stat, $p, $method, $est, $lo, $hi, $achieved) = @$c;
	my $label = sprintf('R %s%s%s %s mu=%s c=%d e=%s%s',
		$xk, ($yk ? "/$yk" : ''), ($paired ? ' paired' : ''),
		$alt, $mu, $correct, (defined $exact ? $exact : 'auto'),
		($ci ? " ci=$clevel" : ''));
	my @args = ($DATA{$xk});
	push @args, $DATA{$yk} if $yk;
	push @args, (alternative => $alt, mu => $mu, correct => $correct);
	push @args, (paired => 1) if $paired;
	push @args, (exact => $exact) if defined $exact;
	push @args, (conf_int => 1, conf_level => $clevel, tol_root => 1e-12) if $ci;
	my $r;
	{
		# The only warnings the corpus can raise are R's own two: a
		# zero-variance approximation and an unachievable conf.level.
		local $SIG{__WARN__} = sub { };
		$r = wilcox_test(@args);
	}
	close_to($r->{statistic}, $stat, $TOL_STAT, "$label: statistic");
	if ($p eq 'NaN') {
		# Every value tied and the approximation asked for: R divides by a
		# zero variance and reports NaN, we warn and report 1.  Asserted as
		# a divergence at the end of this file too.
		is($r->{p_value}, 1, "$label: p is 1 where R gives NaN (zero variance)");
	} else {
		close_to($r->{p_value}, $p, $TOL_P, "$label: p");
	}
	is($r->{method}, $method, "$label: method");
	if ($ci) {
		close_to($r->{estimate},    $est, $TOL_CI, "$label: estimate",         $TOL_CI_ABS);
		close_to($r->{conf_int}[0], $lo,  $TOL_CI, "$label: conf_int lower",   $TOL_CI_ABS);
		close_to($r->{conf_int}[1], $hi,  $TOL_CI, "$label: conf_int upper",   $TOL_CI_ABS);
		close_to($r->{conf_level},  $achieved, $TOL_CI, "$label: achieved conf.level");
	}
}

# ===========================================================================
# 2. SciPy TestMannWhitneyU (scipy/stats/tests/test_hypotests.py)
#
# "All magic numbers are from R wilcox.test", per the class header.  SciPy's
# mannwhitneyu(x, y) statistic is R's W for wilcox.test(x, y), so both carry
# over unchanged.  SciPy's method="asymptotic" is R's exact=FALSE and its
# use_continuity=False is R's correct=FALSE.
# ===========================================================================

my @MWU_X = (210.052110, 110.190630, 307.918612);
my @MWU_Y = (436.08811482466416, 416.37397329768191, 179.96975939463582,
             197.8118754228619, 34.038757281225756, 138.54220550921517,
             128.7769351470246, 265.92721427951852, 275.6617533155341,
             592.34083395416258, 448.73177590617018, 300.61495185038905,
             187.97508449019588);

# cases_basic: wilcox.test(x, y, alternative = ..., exact = ...)
foreach my $c ( ['two.sided', 0, 16, 0.6865041817876],
                ['less',      0, 16, 0.3432520908938],
                ['greater',   0, 16, 0.7047591913255],
                ['two.sided', 1, 16, 0.7035714285714],
                ['less',      1, 16, 0.3517857142857],
                ['greater',   1, 16, 0.6946428571429] ) {
	my ($alt, $ex, $w, $p) = @$c;
	my $r = wilcox_test(\@MWU_X, \@MWU_Y, alternative => $alt, exact => $ex);
	close_to($r->{statistic}, $w, $TOL_STAT, "SciPy cases_basic $alt exact=$ex: W");
	close_to($r->{p_value},   $p, 1e-12,     "SciPy cases_basic $alt exact=$ex: p");
}

# cases_continuity: the samples the other way round, so that "less" and
# "greater" swap.  They would not if the continuity correction went on with
# the wrong sign, which is what this case exists to catch.
foreach my $c ( ['two.sided', 1, 23, 0.6865041817876],
                ['less',      1, 23, 0.7047591913255],
                ['greater',   1, 23, 0.3432520908938],
                ['two.sided', 0, 23, 0.6377328900502],
                ['less',      0, 23, 0.6811335549749],
                ['greater',   0, 23, 0.3188664450251] ) {
	my ($alt, $corr, $w, $p) = @$c;
	my $r = wilcox_test(\@MWU_Y, \@MWU_X,
		alternative => $alt, exact => 0, correct => $corr);
	close_to($r->{statistic}, $w, $TOL_STAT, "SciPy cases_continuity $alt correct=$corr: W");
	close_to($r->{p_value},   $p, 1e-12,     "SciPy cases_continuity $alt correct=$corr: p");
}

# cases_9184: the Hollander & Wolfe permeability data, all nine combinations
# of alternative x {correct, no correct, exact}.
my @HW_X = (0.80, 0.83, 1.89, 1.04, 1.45, 1.38, 1.91, 1.64, 0.73, 1.46);
my @HW_Y = (1.15, 0.88, 0.90, 0.74, 1.21);
foreach my $c ( [1, 'less',      0, 0.900775348204],
                [1, 'greater',   0, 0.1223118025635],
                [1, 'two.sided', 0, 0.244623605127],
                [0, 'less',      0, 0.8896643190401],
                [0, 'greater',   0, 0.1103356809599],
                [0, 'two.sided', 0, 0.2206713619198],
                [1, 'less',      1, 0.8967698967699],
                [1, 'greater',   1, 0.1272061272061],
                [1, 'two.sided', 1, 0.2544122544123] ) {
	my ($corr, $alt, $ex, $p) = @$c;
	my $r = wilcox_test(\@HW_X, \@HW_Y,
		alternative => $alt, exact => $ex, correct => $corr);
	close_to($r->{statistic}, 35, $TOL_STAT, "SciPy gh-9184 $alt e=$ex c=$corr: W");
	close_to($r->{p_value},   $p, 1e-12,     "SciPy gh-9184 $alt e=$ex c=$corr: p");
}

# cases_2118: U == m*n/2 exactly, where an unguarded continuity correction
# pushes the two-sided p above 1.
foreach my $c ( [[1,2,3], [1.5,2.5], 'greater',   3,   0.6135850036578],
                [[1,2,3], [1.5,2.5], 'less',      3,   0.6135850036578],
                [[1,2,3], [1.5,2.5], 'two.sided', 3,   1.0],
                [[1,2,3], [2],       'greater',   1.5, 0.681324055883],
                [[1,2,3], [2],       'less',      1.5, 0.681324055883],
                [[1,2,3], [2],       'two.sided', 1.5, 1.0],
                [[1,2],   [1,2],     'greater',   2,   0.667497228949],
                [[1,2],   [1,2],     'less',      2,   0.667497228949],
                [[1,2],   [1,2],     'two.sided', 2,   1.0] ) {
	my ($x, $y, $alt, $w, $p) = @$c;
	my $r = wilcox_test($x, $y, alternative => $alt, exact => 0);
	close_to($r->{statistic}, $w, $TOL_STAT, "SciPy gh-2118 [@$x] vs [@$y] $alt: W");
	close_to($r->{p_value},   $p, 1e-12,     "SciPy gh-2118 [@$x] vs [@$y] $alt: p");
}

# test_tie_correct: the same x against seven y vectors that differ only in
# where the ties fall, so that the tie correction in the variance is what
# separates the p-values.
{
	my @x  = (1, 2, 3, 4);
	my @y0 = (1, 2, 3, 4, 5);
	my @dy  = (0, 1, 0, 1, 0);
	my @dy2 = (0, 0, 1, 0, 0);
	my @ys = (
		[map { $_ - 0.01 } @y0],
		[map { $y0[$_] - 0.01 * $dy[$_]  } 0 .. 4],
		[map { $y0[$_] - 0.01 * $dy2[$_] } 0 .. 4],
		[@y0],
		[map { $y0[$_] + 0.01 * $dy2[$_] } 0 .. 4],
		[map { $y0[$_] + 0.01 * $dy[$_]  } 0 .. 4],
		[map { $_ + 0.01 } @y0],
	);
	my @U = (10, 9, 8.5, 8, 7.5, 7, 6);
	my @P = (1, 0.9017048037317, 0.804080657472, 0.7086240584439,
	         0.6197963884941, 0.5368784563079, 0.3912672792826);
	foreach my $i (0 .. $#ys) {
		my $r = wilcox_test(\@x, $ys[$i], exact => 0);
		close_to($r->{statistic}, $U[$i], $TOL_STAT, "SciPy test_tie_correct #$i: W");
		close_to($r->{p_value},   $P[$i], 1e-12,     "SciPy test_tie_correct #$i: p");
	}
}

# test_exact_U_equals_mean: both one-sided exact p-values exceed 0.5, so the
# two-sided one has to be clamped rather than reported as 1.2.
{
	my $l = wilcox_test([1,2,3], [1.5,2.5], alternative => 'less',      exact => 1);
	my $g = wilcox_test([1,2,3], [1.5,2.5], alternative => 'greater',   exact => 1);
	my $t = wilcox_test([1,2,3], [1.5,2.5], alternative => 'two.sided', exact => 1);
	close_to($l->{p_value}, $g->{p_value}, 1e-15, 'SciPy U==mn/2: exact tails agree');
	ok($l->{p_value} > 0.5, 'SciPy U==mn/2: each exact tail exceeds 0.5');
	close_to($t->{statistic}, 3, $TOL_STAT, 'SciPy U==mn/2: W');
	close_to($t->{p_value},   1, 1e-15,     'SciPy U==mn/2: two-sided p clamped to 1');
}

# test_gh_11355b: +/-Inf is not missing data, it is the largest (or smallest)
# value, and a rank test handles it.  NaN, by contrast, is R's NA and goes.
{
	my $inf = 9 ** 9 ** 9;
	foreach my $c (
		[[1,2,3,4],       [3,6,7,8,$inf,3,2,1,4,4,5],       10,   0.1297704873477],
		[[1,2,3,4],       [3,6,7,8,$inf,$inf,2,1,4,4,5],    8.5,  0.08735617507695],
		[[1,2,$inf,4],    [3,6,7,8,$inf,3,2,1,4,4,5],       17.5, 0.5988856695752],
		[[1,2,$inf,4],    [3,6,7,8,$inf,$inf,2,1,4,4,5],    16,   0.4687165824462],
		[[1,$inf,$inf,4], [3,6,7,8,$inf,$inf,2,1,4,4,5],    24.5, 0.7912517950119] ) {
		my ($x, $y, $w, $p) = @$c;
		my $r = wilcox_test($x, $y, exact => 0);
		close_to($r->{statistic}, $w, $TOL_STAT, "SciPy gh-11355b W=$w: statistic");
		close_to($r->{p_value},   $p, 1e-11,     "SciPy gh-11355b W=$w: p");
	}
}

# test_mannwhitneyu_{one,two}_sided and their no-continuity twins: n = 30
# against n = 20, so the asymptotic tail is a long way out.
{
	my @X = (19.8958398126694, 19.5452691647182, 19.0577309166425, 21.716543054589,
	         20.3269502208702, 20.0009273294025, 19.3440043632957, 20.4216806548105,
	         19.0649894736528, 18.7808043120398, 19.3680942943298, 19.4848044069953,
	         20.7514611265663, 19.0894948874598, 19.4975522356628, 18.9971170734274,
	         20.3239606288208, 20.6921298083835, 19.0724259532507, 18.9825187935021,
	         19.5144462609601, 19.8256857844223, 20.5174677102032, 21.1122407995892,
	         17.9490854922535, 18.2847521114727, 20.1072217648826, 18.6439891962179,
	         20.4970638083542, 19.5567594734914);
	my @Y = (19.2790668029091, 16.993808441865, 18.5416338448258, 17.2634018833575,
	         19.1577183624616, 18.5119655377495, 18.6068455037221, 18.8358343362655,
	         19.0366413269742, 18.1135025515417, 19.2201873866958, 17.8344909022841,
	         18.2894380745856, 18.6661374133922, 19.9688601693252, 16.0672254617636,
	         19.00596360572, 19.201561539032, 19.0487501090183, 19.0847908674356);
	foreach my $c (
		[1, 'less',      0.999957683256589],
		[1, 'greater',   4.5941632666275e-05],
		[1, 'two.sided', 9.188326533255e-05],
		[0, 'less',      0.999955905990004],
		[0, 'greater',   4.40940099958089e-05],
		[0, 'two.sided', 8.81880199916178e-05] ) {
		my ($corr, $alt, $p) = @$c;
		my $r = wilcox_test(\@X, \@Y,
			alternative => $alt, exact => 0, correct => $corr);
		close_to($r->{statistic}, 498, $TOL_STAT, "SciPy MWU 30v20 $alt c=$corr: W");
		close_to($r->{p_value},   $p,  1e-11,     "SciPy MWU 30v20 $alt c=$corr: p");
		# X and Y interchanged must give the mirrored W and the same p.
		my $s = wilcox_test(\@Y, \@X,
			alternative => ($alt eq 'less' ? 'greater' : $alt eq 'greater' ? 'less' : $alt),
			exact => 0, correct => $corr);
		close_to($s->{statistic}, 102, $TOL_STAT, "SciPy MWU 20v30 $alt c=$corr: W");
		close_to($s->{p_value},   $p,  1e-11,     "SciPy MWU 20v30 $alt c=$corr: p");
	}
}

# ===========================================================================
# 3. SciPy TestWilcoxon (scipy/stats/tests/test_morestats.py)
#
# SciPy reports min(T+, T-); R and this module report V, so the p-values are
# what carries over.  Where SciPy's own comment gives the R call that produced
# the number, that call is what is reproduced here.
# ===========================================================================

# test_accuracy_wilcoxon, the block SciPy annotates
#   > wilcox.test(x, y, paired=TRUE, exact=FALSE, correct={FALSE,TRUE})
{
	my @x = (120, 114, 181, 188, 180, 146, 121, 191, 132, 113, 127, 112);
	my @y = (133, 143, 119, 189, 112, 199, 198, 113, 115, 121, 142, 187);
	my $a = wilcox_test(\@x, \@y, paired => 1, exact => 0, correct => 0);
	close_to($a->{statistic}, 34, $TOL_STAT, 'SciPy accuracy_wilcoxon: V');
	close_to($a->{p_value}, 0.6948866023724735, 1e-12, 'SciPy accuracy_wilcoxon correct=F: p');
	my $b = wilcox_test(\@x, \@y, paired => 1, exact => 0, correct => 1);
	close_to($b->{statistic}, 34, $TOL_STAT, 'SciPy accuracy_wilcoxon: V (corrected)');
	close_to($b->{p_value}, 0.7240816609153895, 1e-12, 'SciPy accuracy_wilcoxon correct=T: p');
}

# test_wilcoxon_tie (gh-2391), SciPy's comment giving
#   > wilcox.test(rep(0.1, 10), exact=FALSE, correct={FALSE,TRUE})
# Every value is identical and positive: V is its maximum, and the tie
# correction is the only thing keeping the variance away from the untied one.
{
	my @d = (0.1) x 10;
	my $a = wilcox_test(\@d, exact => 0, correct => 0);
	close_to($a->{statistic}, 55, $TOL_STAT, 'SciPy wilcoxon_tie: V = 55');
	close_to($a->{p_value}, 0.001565402258002551, 1e-12, 'SciPy wilcoxon_tie correct=F: p');
	my $b = wilcox_test(\@d, exact => 0, correct => 1);
	close_to($b->{p_value}, 0.00190419504300439, 1e-12, 'SciPy wilcoxon_tie correct=T: p');
}

# test_onesided, tested upstream against "R version 4.0.3".  One pair is tied
# (140, 140), so a zero difference is dropped before the approximation.
{
	my @x = (125, 115, 130, 140, 140, 115, 140, 125, 140, 135);
	my @y = (110, 122, 125, 120, 140, 124, 123, 137, 135, 145);
	foreach my $c ( ['less',    0, 0.7031847042787],
	                ['less',    1, 0.72336564289],
	                ['greater', 0, 0.2968152957213],
	                ['greater', 1, 0.3176446594176] ) {
		my ($alt, $corr, $p) = @$c;
		my $r = wilcox_test(\@x, \@y,
			paired => 1, exact => 0, correct => $corr, alternative => $alt);
		close_to($r->{statistic}, 27, $TOL_STAT, "SciPy onesided $alt c=$corr: V");
		close_to($r->{p_value},   $p, 1e-12,     "SciPy onesided $alt c=$corr: p");
	}
}

# test_exact_pval, SciPy's comment giving
#   > wilcox.test(x - y, exact=TRUE, alternative=...)
{
	my @x = (1.81, 0.82, 1.56, -0.48, 0.81, 1.28, -1.04, 0.23, -0.75, 0.14);
	my @y = (0.71, 0.65, -0.2, 0.85, -1.1, -0.45, -0.84, -0.24, -0.68, -0.76);
	foreach my $c ( ['two.sided', 0.10546875],
	                ['less',      0.95800781256],
	                ['greater',   0.052734375] ) {
		my ($alt, $p) = @$c;
		my $r = wilcox_test(\@x, \@y, paired => 1, exact => 1, alternative => $alt);
		close_to($r->{statistic}, 44, $TOL_STAT, "SciPy exact_pval $alt: V");
		close_to($r->{p_value},   $p, 1e-10,     "SciPy exact_pval $alt: p");
	}
	# n = 20, and the differences are all distinct, so this is the largest
	# untied signed-rank table the default path builds.
	my @a = map { $_ + 0.5 } 0 .. 19;
	my @b = map { 20 - $_ } 0 .. 19;
	foreach my $c ( ['two.sided', 0.8694877624511719],
	                ['less',      0.4347438812255859],
	                ['greater',   0.5795888900756836] ) {
		my ($alt, $p) = @$c;
		my $r = wilcox_test(\@a, \@b, paired => 1, exact => 1, alternative => $alt);
		close_to($r->{p_value}, $p, 1e-12, "SciPy exact_pval n=20 $alt: p");
	}
}

# test_exact_p_1: inputs built so V sits at (or just left of) the centre of
# the support, where the two-sided p has to come out exactly 1.
foreach my $x ( [-1,-2,3], [-1,2,-3,-4,5], [-1,-2,3,-4,-5,-6,7,8] ) {
	my $r = wilcox_test($x);
	my $want = 0;
	$want += $_ for grep { $_ > 0 } @$x;
	close_to($r->{statistic}, $want, $TOL_STAT, "SciPy exact_p_1 [@$x]: V");
	close_to($r->{p_value},   1,     1e-15,     "SciPy exact_p_1 [@$x]: p = 1");
}

# test_all_zeros_exact: every difference is zero.  The old code croaked here,
# because it dropped the zeroes and then found nothing left; R and SciPy both
# report V = 0 with p = 1, which is what the permutation distribution over an
# empty set of sign flips says.
{
	my $r = wilcox_test([0, 0, 0, 0, 0]);
	close_to($r->{statistic}, 0, $TOL_STAT, 'SciPy all_zeros_exact: V = 0');
	close_to($r->{p_value},   1, 1e-15,     'SciPy all_zeros_exact: p = 1');
	is($r->{method}, 'Wilcoxon signed rank exact test',
		'SciPy all_zeros_exact: stays on the exact path');
}

# test_symmetry_gh19872_gh20752: one-sided tests must be mirror images of each
# other under exchange of the samples.  These data are tied, so the statistic
# is a half-integer and the exact test is the conditional one.
{
	my @v1 = (62, 66, 61, 68, 74, 62, 68, 62, 55, 59);
	my @v2 = (71, 71, 69, 61, 75, 71, 77, 72, 62, 65);
	foreach my $ex (1, 0) {
		my $ref = wilcox_test(\@v1, \@v2, paired => 1, alternative => 'less',    exact => $ex);
		my $res = wilcox_test(\@v2, \@v1, paired => 1, alternative => 'greater', exact => $ex);
		isnt($res->{statistic}, int($res->{statistic}),
			"SciPy gh-19872 exact=$ex: the statistic is a half-integer");
		close_to(10 * 11 / 2 - $res->{statistic}, $ref->{statistic}, $TOL_STAT,
			"SciPy gh-19872 exact=$ex: V mirrors");
		close_to($res->{p_value}, $ref->{p_value}, 1e-13,
			"SciPy gh-19872 exact=$ex: p mirrors");
	}
	# R 4.6.1: wilcox.test(v1, v2, paired = TRUE, alternative = "less")
	my $r = wilcox_test(\@v1, \@v2, paired => 1, alternative => 'less');
	close_to($r->{statistic}, 4.5,       $TOL_STAT, 'gh-19872 default: V = 4.5');
	close_to($r->{p_value},   0.0078125, 1e-13,     'gh-19872 default: exact p matches R');
	is($r->{method}, 'Wilcoxon signed rank exact test',
		'gh-19872 default: ties no longer force the approximation');
}

# ===========================================================================
# 4. R's own regression tests
# ===========================================================================

# tests/reg-tests-1a.R, PR#1150: "Wilcoxon rank sum and signed rank tests did
# not return the Hodges-Lehmann estimators of the associated confidence
# interval".  Upstream checks these to 3-4 decimals against Hollander & Wolfe
# (1999) 2nd ed.; the full-precision values are R 4.6.1's own.
{
	my @x = (1.83,  0.50,  1.62,  2.48, 1.68, 1.88, 1.55, 3.06, 1.30);
	my @y = (0.878, 0.647, 0.598, 2.05, 1.06, 1.29, 1.06, 3.14, 1.29);
	# NOTE the order: y then x, as upstream has it.
	my $we = wilcox_test(\@y, \@x, paired => 1, conf_int => 1);
	close_to($we->{p_value},    0.0390625, 1e-14, 'R PR#1150 paired: p (H&W 0.0391)');
	close_to($we->{estimate},  -0.46,      1e-13, 'R PR#1150 paired: estimate (H&W -0.46)');
	close_to($we->{conf_int}[0], -0.786,   1e-13, 'R PR#1150 paired: lower (H&W -0.786)');
	close_to($we->{conf_int}[1], -0.01,    1e-13, 'R PR#1150 paired: upper (H&W -0.010)');
	close_to($we->{conf_level},  0.9609375, 1e-14, 'R PR#1150 paired: achieved level');

	my @x2 = (0.80, 0.83, 1.89, 1.04, 1.45, 1.38, 1.91, 1.64, 0.73, 1.46);
	my @y2 = (1.15, 0.88, 0.90, 0.74, 1.21);
	my $w2 = wilcox_test(\@y2, \@x2, conf_int => 1);
	close_to($w2->{p_value},     0.2544122544122544, 1e-13, 'R PR#1150 2-sample: p (H&W 0.2544)');
	close_to($w2->{estimate},   -0.305,  1e-13, 'R PR#1150 2-sample: estimate (H&W -0.305)');
	close_to($w2->{conf_int}[0], -0.76,  1e-13, 'R PR#1150 2-sample: lower (H&W -0.76)');
	close_to($w2->{conf_int}[1],  0.15,  1e-13, 'R PR#1150 2-sample: upper (H&W 0.15)');
	close_to($w2->{conf_level},   0.96003996003996006, 1e-13, 'R PR#1150 2-sample: achieved level');
}

# tests/reg-tests-1b.R: "extreme example of two-sample wilcox.test, reported
# by Wolfgang Huber to R-devel, 2008-01-01. normal approximation is way off
# here."  The interval collapses onto the endpoints of the search bracket,
# which is the case R's two-sample root() has its endpoint shortcut for.
{
	my @y = (2 .. 60);
	my $r = wilcox_test([1], \@y, conf_int => 1, exact => 0);
	close_to($r->{statistic}, 0, $TOL_STAT, 'R reg-1b Huber: W = 0');
	close_to($r->{p_value},   0.094022875902539016, 1e-12, 'R reg-1b Huber: p');
	close_to($r->{estimate},  -30, 1e-12, 'R reg-1b Huber: estimate');
	close_to($r->{conf_int}[0], -59, 1e-12, 'R reg-1b Huber: lower');
	close_to($r->{conf_int}[1],  -1, 1e-12, 'R reg-1b Huber: upper');
}

# tests/reg-tests-1b.R: "(asymptotic) point estimate in wilcox.test(*,
# conf.int=TRUE)" -- it "was continuity corrected, dependent on 'alternative',
# prior to 2.10.1", so the estimate must not move with the alternative.
{
	my @Z = (-2, 0, 1, 1, 2, 2, 3, 5, 5, 5, 7);
	my @e1 = map { wilcox_test(\@Z, conf_int => 1, exact => 0, alternative => $_)->{estimate} }
	         qw(two.sided less greater);
	is($e1[1], $e1[0], 'R reg-1b: one-sample estimate is the same for less');
	is($e1[2], $e1[0], 'R reg-1b: one-sample estimate is the same for greater');

	my @X = (6.5, 6.8, 7.1, 7.3, 10.2);
	my @Y = (5.8, 5.8, 5.9, 6, 6, 6, 6.3, 6.3, 6.4, 6.5, 6.5);
	my @e2 = map { wilcox_test(\@X, \@Y, conf_int => 1, exact => 0, alternative => $_)->{estimate} }
	         qw(two.sided less greater);
	is($e2[1], $e2[0], 'R reg-1b: two-sample estimate is the same for less');
	is($e2[2], $e2[0], 'R reg-1b: two-sample estimate is the same for greater');
}

# tests/reg-tests-1d.R line 332: six degenerate one-sample calls that must all
# return a result.  Upstream now runs them under options(warn = 2), i.e. no
# warning is permitted at all, with the comment "For R >= 4.6.0 warnings for
# exact with ties are gone".
foreach my $c ( [[0],       0,   1],
                [[1],       1,   1],
                [[0,1],     2,   1],
                [[1,2],     3,   0.5],
                [[1,1],     3,   0.5],
                [[-1,0,1],  2.5, 1] ) {
	my ($x, $v, $p) = @$c;
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	my $r = wilcox_test($x);
	close_to($r->{statistic}, $v, $TOL_STAT, "R reg-1d degenerate [@$x]: V");
	close_to($r->{p_value},   $p, 1e-14,     "R reg-1d degenerate [@$x]: p");
	is(scalar @w, 0, "R reg-1d degenerate [@$x]: no warning");
	is($r->{method}, 'Wilcoxon signed rank exact test',
		"R reg-1d degenerate [@$x]: exact");
}

# tests/reg-tests-1d.R line 3525: "wilcox.test(x,{y,} ..): when 'x' and/or 'y'
# contain +/- Inf".  Upstream asserts the results are identical whether the
# large value is 1000 or Inf, and -- the part that used to be an error in R
# and a wrong answer here -- that a paired test whose Inf - Inf differences
# are NaN gives the same answer as the same data without those pairs at all.
{
	my $inf = 9 ** 9 ** 9;
	foreach my $nm ('shifted', 'ties') {
		my $bump = ($nm eq 'shifted') ? 1/8 : 0;
		my @a = map { $_ + $bump } (9, 8, 7, 6, 5, 4);
		foreach my $L (1000, $inf) {
			my $big = wilcox_test([1 .. 7], [@a, $L + $bump]);
			my $ref = wilcox_test([1 .. 7], [@a, 1000 + $bump]);
			close_to($big->{statistic}, $ref->{statistic}, $TOL_STAT,
				"R reg-1d Inf ($nm) two-sample L=$L: W");
			close_to($big->{p_value}, $ref->{p_value}, 1e-14,
				"R reg-1d Inf ($nm) two-sample L=$L: p");
			my $one = wilcox_test([@a, $L + $bump]);
			my $one_ref = wilcox_test([@a, 1000 + $bump]);
			close_to($one->{p_value}, $one_ref->{p_value}, 1e-14,
				"R reg-1d Inf ($nm) one-sample L=$L: p");
		}
	}
	# "Inf-Inf etc broken in paired case in R <= 3.6.x": all three of these
	# must agree, because the NaN differences are dropped as missing.
	my $w0  = wilcox_test([1 .. 5],                [0, 4, 8, 12, 16],                paired => 1);
	my $w1  = wilcox_test([1 .. 5, $inf],          [0, 4, 8, 12, 16, $inf],          paired => 1);
	my $wII = wilcox_test([-$inf, 1 .. 5, $inf],   [-$inf, 0, 4, 8, 12, 16, $inf],   paired => 1);
	close_to($w0->{statistic}, 1,     $TOL_STAT, 'R reg-1d paired Inf: w0 V');
	close_to($w0->{p_value},   0.125, 1e-15,     'R reg-1d paired Inf: w0 p');
	foreach my $c ([$w1, 'w1'], [$wII, 'wII']) {
		my ($r, $nm) = @$c;
		close_to($r->{statistic}, $w0->{statistic}, $TOL_STAT, "R reg-1d paired Inf: $nm V matches w0");
		close_to($r->{p_value},   $w0->{p_value},   1e-15,     "R reg-1d paired Inf: $nm p matches w0");
		is($r->{method}, $w0->{method}, "R reg-1d paired Inf: $nm method matches w0");
	}
}

# ===========================================================================
# 5. R's man page examples, whose printed output is pinned in
#    tests/Examples/stats-Ex.Rout.save
# ===========================================================================
{
	my @x = (1.83,  0.50,  1.62,  2.48, 1.68, 1.88, 1.55, 3.06, 1.30);
	my @y = (0.878, 0.647, 0.598, 2.05, 1.06, 1.29, 1.06, 3.14, 1.29);
	# V = 40, p-value = 0.01953
	my $a = wilcox_test(\@x, \@y, paired => 1, alternative => 'greater');
	close_to($a->{statistic}, 40, $TOL_STAT, 'R man 1-sample: V = 40');
	close_to($a->{p_value}, 0.01953125, 1e-14, 'R man 1-sample: p = 0.01953');
	is($a->{method}, 'Wilcoxon signed rank exact test', 'R man 1-sample: method');
	# wilcox.test(y - x, alternative = "less")  # The same.
	my @d = map { $y[$_] - $x[$_] } 0 .. $#x;
	my $b = wilcox_test(\@d, alternative => 'less');
	close_to($b->{statistic}, 5, $TOL_STAT, 'R man y-x: V = 5');
	close_to($b->{p_value}, 0.01953125, 1e-14, 'R man y-x: same p');
	# ... exact = FALSE, correct = FALSE: "H&W large sample approximation"
	my $c = wilcox_test(\@d, alternative => 'less', exact => 0, correct => 0);
	close_to($c->{p_value}, 0.019075855086707564, 1e-12, 'R man y-x approx: p = 0.01908');
	is($c->{method}, 'Wilcoxon signed rank test', 'R man y-x approx: method');
	# The formula-interface examples reduce to the two-sided versions.
	my $e = wilcox_test(\@d);
	close_to($e->{p_value}, 0.0390625, 1e-14, 'R man change ~ 1: p = 0.03906');
	my $f = wilcox_test(\@x, \@y, paired => 1);
	close_to($f->{statistic}, 40, $TOL_STAT, 'R man Pair(first, second): V = 40');
	close_to($f->{p_value}, 0.0390625, 1e-14, 'R man Pair(first, second): p = 0.03906');
}
{
	# W = 35, p-value = 0.1272 / 0.1103
	my @x = (0.80, 0.83, 1.89, 1.04, 1.45, 1.38, 1.91, 1.64, 0.73, 1.46);
	my @y = (1.15, 0.88, 0.90, 0.74, 1.21);
	my $a = wilcox_test(\@x, \@y, alternative => 'greater');
	close_to($a->{statistic}, 35, $TOL_STAT, 'R man 2-sample: W = 35');
	close_to($a->{p_value}, 0.12720612720612721, 1e-13, 'R man 2-sample: p = 0.1272');
	is($a->{method}, 'Wilcoxon rank sum exact test', 'R man 2-sample: method');
	my $b = wilcox_test(\@x, \@y, alternative => 'greater', exact => 0, correct => 0);
	close_to($b->{p_value}, 0.11033568095992309, 1e-12, 'R man 2-sample approx: p = 0.1103');
}
{
	# wilcox.test(Ozone ~ Month, data = airquality, subset = Month %in% c(5,8))
	#   W = 127.5, p-value = 6.109e-05, "Wilcoxon rank sum exact test"
	# W is a half-integer, so this is the tied exact path: before R 4.6.0 the
	# same call printed 0.0001208 from the normal approximation.
	my @may = (41,36,12,18,28,23,19,8,7,16,11,14,18,14,34,6,30,11,1,11,4,32,23,45,115,37);
	my @aug = (39,9,16,78,35,66,122,89,110,44,28,65,22,59,23,31,44,21,9,45,168,73,76,118,84,85);
	my $r = wilcox_test(\@may, \@aug);
	close_to($r->{statistic}, 127.5, $TOL_STAT, 'R man Ozone: W = 127.5');
	close_to($r->{p_value}, 6.1087351888037202e-05, 1e-11, 'R man Ozone: p = 6.109e-05');
	is($r->{method}, 'Wilcoxon rank sum exact test', 'R man Ozone: exact with ties');
	my $a = wilcox_test(\@may, \@aug, exact => 0);
	close_to($a->{p_value}, 0.00012080783076877442, 1e-12, 'R man Ozone: approximate p');
}
{
	# "accuracy in ties determination via 'digits.rank'".  0.4 - 0.3 and
	# 0.3 - 0.2 and 0.2 - 0.1 are three different doubles, so without
	# rounding they are not ties at all; digits.rank = 9 makes them ties
	# again, as they are for 4:2 against 3:1.
	my $plain = wilcox_test([4,3,2], [3,2,1], paired => 1);
	close_to($plain->{statistic}, 6, $TOL_STAT, 'R man digits.rank: integer V = 6');
	close_to($plain->{p_value}, 0.25, 1e-14, 'R man digits.rank: integer p = 0.25');
	my $tenths = wilcox_test([0.4,0.3,0.2], [0.3,0.2,0.1], paired => 1);
	close_to($tenths->{statistic}, 6, $TOL_STAT, 'R man digits.rank: tenths V = 6');
	close_to($tenths->{p_value}, 0.25, 1e-14, 'R man digits.rank: tenths p = 0.25');
	my $rounded = wilcox_test([0.4,0.3,0.2], [0.3,0.2,0.1], paired => 1, digits_rank => 9);
	close_to($rounded->{statistic}, 6, $TOL_STAT, 'R man digits.rank = 9: V = 6');
	close_to($rounded->{p_value}, 0.25, 1e-14, 'R man digits.rank = 9: p = 0.25');
	# digits.rank changes the answer where it changes which values are tied.
	# Every value here is a dyadic rational and so is exact in a double, an
	# x87 long double and a __float128 alike; that matters, because whether
	# two of them tie after rounding is the whole point of the case and must
	# not depend on the NV width.  |differences| are 1 and 1.001953125 (which
	# is 1 + 1/512) plus 2, 3, 5, 6.
	#   R 4.6.1, wilcox.test(d, digits.rank = k):
	#     k = Inf or 7 -> V = 15,   p = 0.43750000000000017  (nothing ties)
	#     k = 3        -> V = 15.5, p = 0.34375              (the first two tie)
	my @d = (1, -1.001953125, 2, -3, 5, 6);
	my $sharp = wilcox_test(\@d, digits_rank => 7);
	close_to($sharp->{statistic}, 15, $TOL_STAT, 'digits_rank => 7: V = 15');
	close_to($sharp->{p_value}, 0.43750000000000017, 1e-13, 'digits_rank => 7: p');
	my $blunt = wilcox_test(\@d, digits_rank => 3);
	close_to($blunt->{statistic}, 15.5, $TOL_STAT,
		'digits_rank => 3: two |differences| tie, so V is a half-integer');
	close_to($blunt->{p_value}, 0.34375, 1e-14, 'digits_rank => 3: p');
	isnt($sharp->{p_value}, $blunt->{p_value},
		'digits_rank: rounding to 3 significant digits changes which values tie');
	# digits_rank => undef is R's default of Inf: no rounding at all.
	my $none = wilcox_test(\@d, digits_rank => undef);
	is($none->{p_value}, $sharp->{p_value}, 'digits_rank => undef means no rounding');
	my $dflt = wilcox_test(\@d);
	is($dflt->{p_value}, $sharp->{p_value}, 'no digits_rank means no rounding');

	# tol.root, at its default and tightened.  The asymptotic interval is the
	# root of a step function, so it is only ever pinned down to tol.root --
	# which is why the generated corpus above asks for 1e-12 rather than
	# freezing where Brent's method happened to stop on one NV width.  R:
	#   wilcox.test(x, y, conf.int = TRUE, exact = FALSE)
	#     tol.root default -> (-1.7500391867544811, -0.24996081324551894)
	#     tol.root = 1e-12 -> (-1.7500000000000551, -0.24999999999994513)
	my @tx = map { $_ / 4 } 1 .. 10;
	my @ty = map { $_ / 4 + 0.5 } 3 .. 12;
	my $loose = wilcox_test(\@tx, \@ty, conf_int => 1, exact => 0);
	my $tight = wilcox_test(\@tx, \@ty, conf_int => 1, exact => 0, tol_root => 1e-12);
	close_to($loose->{conf_int}[0], -1.75, 2e-4, 'default tol.root: lower limit within 1e-4');
	close_to($loose->{conf_int}[1], -0.25, 2e-3, 'default tol.root: upper limit within 1e-4');
	close_to($tight->{conf_int}[0], -1.7500000000000551, 1e-10, 'tol.root = 1e-12: lower limit');
	close_to($tight->{conf_int}[1], -0.24999999999994513, 1e-10, 'tol.root = 1e-12: upper limit');
	close_to($tight->{estimate}, -1, 1e-10, 'tol.root = 1e-12: estimate');
}

# ===========================================================================
# 6. The Edgeworth series (R 4.6.0's integer 'correct')
#
# R spells this correct = 0..3, in which 0 still applies the continuity
# correction and only FALSE turns it off.  Here `correct` stays a plain
# boolean and the number of Edgeworth terms is a separate `edgeworth`
# argument, so R's correct = k is our correct => 1, edgeworth => k.
# Values from R 4.6.1 at options(digits = 17).
# ===========================================================================
{
	my @x = (0.80, 0.83, 1.89, 1.04, 1.45, 1.38, 1.91, 1.64, 0.73, 1.46);
	my @y = (1.15, 0.88, 0.90, 0.74, 1.21);
	my @two = (
		[0, 'two.sided', 0.24462360512698345], [0, 'less', 0.90077534820399385], [0, 'greater', 0.12231180256349168],
		[1, 'two.sided', 0.25384667768243574], [1, 'less', 0.89718780550049926], [1, 'greater', 0.12692333884121787],
		[2, 'two.sided', 0.2546703636805796 ], [2, 'less', 0.89704543672539239], [2, 'greater', 0.12733518184028977],
		[3, 'two.sided', 0.25470826096978083], [3, 'less', 0.89679648712154247], [3, 'greater', 0.12735413048489042],
	);
	foreach my $c (@two) {
		my ($k, $alt, $p) = @$c;
		my $r = wilcox_test(\@x, \@y,
			exact => 0, correct => 1, edgeworth => $k, alternative => $alt);
		close_to($r->{p_value}, $p, 1e-12, "R correct=$k two-sample $alt: p");
	}
	my @z = (-2, 0.5, 1.25, 1.75, 2.5, 2.25, 3.5, 5.5, 5.25, 5.75, 7.5);
	my @one = (
		[0, 'two.sided', 0.011278190116074116], [0, 'less', 0.9956403722735554 ], [0, 'greater', 0.0056390950580370216],
		[1, 'two.sided', 0.0076483268837976848], [1, 'less', 0.99733431636745018], [1, 'greater', 0.0038241634418987982],
		[2, 'two.sided', 0.0072296646454956814], [2, 'less', 0.99747393576953147], [2, 'greater', 0.00361483232274778  ],
		[3, 'two.sided', 0.0070096530420635794], [3, 'less', 0.99761862655291489], [3, 'greater', 0.0035048265210317446],
	);
	foreach my $c (@one) {
		my ($k, $alt, $p) = @$c;
		my $r = wilcox_test(\@z,
			exact => 0, correct => 1, edgeworth => $k, alternative => $alt);
		close_to($r->{statistic}, 62, $TOL_STAT, "R correct=$k one-sample $alt: V");
		close_to($r->{p_value},   $p, 1e-12,     "R correct=$k one-sample $alt: p");
	}
	# R turns the series off when ties (or, for the signed rank test, zeroes)
	# are present, because it is derived for untied ranks.
	my @tied = (1, 2, 2, 3, 4, 4, 5, 6);
	foreach my $k (1, 2, 3) {
		my $on  = wilcox_test(\@tied, [6,7,7,8,9,9,10,11], exact => 0, edgeworth => $k);
		my $off = wilcox_test(\@tied, [6,7,7,8,9,9,10,11], exact => 0, edgeworth => 0);
		is($on->{p_value}, $off->{p_value},
			"edgeworth => $k is ignored on tied two-sample data, as in R");
	}
	my @zeroes = (0, 1, 2, 3, -4, 5);
	foreach my $k (1, 2, 3) {
		my $on  = wilcox_test(\@zeroes, exact => 0, edgeworth => $k);
		my $off = wilcox_test(\@zeroes, exact => 0, edgeworth => 0);
		is($on->{p_value}, $off->{p_value},
			"edgeworth => $k is ignored when a zero was dropped, as in R");
	}
	# edgeworth only ever applies to the approximation.
	my $ex = wilcox_test(\@x, \@y, exact => 1, edgeworth => 3);
	is($ex->{p_value}, wilcox_test(\@x, \@y, exact => 1)->{p_value},
		'edgeworth is irrelevant to the exact test');
}

# ===========================================================================
# 7. Far tails
#
# The exact upper tail used to be computed as 1 - CDF(q - 1), which cancels
# every significant digit away once the true p falls below NV_EPSILON: two
# perfectly separated samples of 30 apiece -- the *default* exact branch --
# came back with p = 0.  Both tails are now summed directly, and the untied
# rank-sum table is folded about its centre before summing so that the tiny
# counts at the far end of a subtractively-built table are never touched.
# Reference values are R 4.6.1's.
# ===========================================================================
foreach my $c ( [10, 5.4125441122345148e-06, 1.0825088224469030e-05],
                [15, 6.4467250378938501e-09, 1.2893450075787700e-08],
                [20, 7.2544445519248438e-12, 1.4508889103849688e-11],
                [25, 7.9107286024486173e-15, 1.5821457204897235e-14],
                [30, 8.4556169460723878e-18, 1.6911233892144776e-17],
                [40, 9.3017018280181260e-24, 1.8603403656036252e-23],
                [49, 3.9250145964816453e-29, 7.8500291929632906e-29] ) {
	my ($m, $greater, $two) = @$c;
	my @a = map { $_ * 1.0 } ($m + 1) .. (2 * $m);
	my @b = map { $_ * 1.0 } 1 .. $m;
	my $g = wilcox_test(\@a, \@b, exact => 1, alternative => 'greater');
	my $t = wilcox_test(\@a, \@b, exact => 1);
	close_to($g->{statistic}, $m * $m, $TOL_STAT, "far tail m=n=$m: W is maximal");
	close_to($g->{p_value}, $greater, 1e-12, "far tail m=n=$m: greater");
	close_to($t->{p_value}, $two,     1e-12, "far tail m=n=$m: two.sided");
}
# The signed-rank upper tail is 2^-n exactly, which the table reproduces
# exactly on a double build; it used to reach 0 from about n = 53.
foreach my $n (20, 30, 40, 49, 60, 120) {
	my $r = wilcox_test([map { $_ * 1.0 } 1 .. $n], exact => 1, alternative => 'greater');
	close_to($r->{p_value}, 2 ** -$n, 1e-12, "far tail signed rank n=$n: p = 2^-$n");
}

# The int that used to hold m * n overflowed for large forced-exact calls, and
# a negative maximum made every statistic look out of range: two perfectly
# separated samples of 50000 came back with p = 1.  It is a size_t now, and
# the table is refused outright rather than attempted, with a message that
# says what to do instead.
{
	my @a = map { $_ * 1.0 } 1 .. 6000;
	my @b = map { $_ * 1.0 } 6001 .. 12000;
	eval { wilcox_test(\@a, \@b, exact => 1) };
	like($@, qr/exact null distribution|exact => 0/,
		'an unreasonably large exact table is refused, not silently wrong');
	my $ok = wilcox_test(\@a, \@b, exact => 0);
	ok($ok->{p_value} < 1e-300, 'the same data through the approximation is still separated');
}

# ===========================================================================
# 8. Result fields and argument surface
# ===========================================================================
{
	my @x = (1.83,  0.50,  1.62,  2.48, 1.68, 1.88, 1.55, 3.06, 1.30);
	my @y = (0.878, 0.647, 0.598, 2.05, 1.06, 1.29, 1.06, 3.14, 1.29);
	my $two = wilcox_test(\@x, \@y, mu => 0.25, conf_int => 1);
	is($two->{statistic_name},  'W',              'two-sample statistic is W');
	is($two->{null_value_name}, 'location shift', 'two-sample null value is a location shift');
	close_to($two->{null_value}, 0.25, 1e-15,     'null_value echoes mu');
	is(ref $two->{conf_int}, 'ARRAY',             'conf_int is an arrayref');
	is(scalar @{ $two->{conf_int} }, 2,           'conf_int has two ends');
	ok($two->{conf_int}[0] <= $two->{estimate},   'estimate is inside the interval (lower)');
	ok($two->{estimate} <= $two->{conf_int}[1],   'estimate is inside the interval (upper)');

	my $one = wilcox_test(\@x);
	is($one->{statistic_name},  'V',        'one-sample statistic is V');
	is($one->{null_value_name}, 'location', 'one-sample null value is a location');
	ok(!exists $one->{conf_int},  'no conf_int unless asked for');
	ok(!exists $one->{estimate},  'no estimate unless asked for');
	ok(!exists $one->{conf_level},'no conf_level unless asked for');

	my $pr = wilcox_test(\@x, \@y, paired => 1);
	is($pr->{statistic_name},  'V',              'paired statistic is V');
	is($pr->{null_value_name}, 'location shift', 'paired null value is a location shift');

	# Both spellings of every dotted argument.
	foreach my $c ( ['conf.int',    'conf_int'],
	                ['conf.level',  'conf_level'],
	                ['digits.rank', 'digits_rank'],
	                ['tol.root',    'tol_root'] ) {
		my ($dotted, $under) = @$c;
		my %v = ('conf.int' => 1, 'conf.level' => 0.9, 'digits.rank' => 6, 'tol.root' => 1e-6);
		my $a = wilcox_test(\@x, \@y, conf_int => 1, $dotted => $v{$dotted});
		my $b = wilcox_test(\@x, \@y, conf_int => 1, $under  => $v{$dotted});
		is($a->{p_value}, $b->{p_value}, "'$dotted' and '$under' are the same argument");
	}

	# A tighter root tolerance moves the asymptotic limits, and only those.
	my $loose = wilcox_test(\@x, \@y, conf_int => 1, exact => 0, tol_root => 1e-2);
	my $tight = wilcox_test(\@x, \@y, conf_int => 1, exact => 0, tol_root => 1e-10);
	isnt($loose->{conf_int}[0], $tight->{conf_int}[0], 'tol_root reaches the root search');
	is($loose->{p_value}, $tight->{p_value},           'tol_root does not touch the p-value');
}

# Argument validation.  Each of these used to be either accepted silently or
# answered with a different test than the caller asked for.
{
	my @x = (1, 2, 3);
	eval { wilcox_test(\@x, []) };
	like($@, qr/not enough 'y' observations/,
		"an empty 'y' stops, rather than quietly running a one-sample test");
	eval { wilcox_test(\@x, [undef, undef]) };
	like($@, qr/not enough 'y' observations/, "an all-missing 'y' stops too");
	eval { wilcox_test([undef, 'x']) };
	like($@, qr/not enough \(non-missing\) 'x' observations/, 'an all-missing x stops');
	eval { wilcox_test(\@x, mu => 9 ** 9 ** 9) };
	like($@, qr/'mu' must be a finite number/, 'an infinite mu is rejected');
	eval { wilcox_test(\@x, mu => (9 ** 9 ** 9) - (9 ** 9 ** 9)) };
	like($@, qr/'mu' must be a finite number/, 'a NaN mu is rejected');
	eval { wilcox_test(\@x, paired => 1) };
	like($@, qr/'y' is missing for paired test/, 'a paired test without y stops');
	eval { wilcox_test(\@x, y => 42) };
	like($@, qr/'y' must be an ARRAY reference/, 'a non-arrayref y is rejected');
	eval { wilcox_test(\@x, conf_int => 1, conf_level => 1) };
	like($@, qr/'conf\.level'/, 'conf.level = 1 is rejected');
	eval { wilcox_test(\@x, conf_int => 1, conf_level => 0) };
	like($@, qr/'conf\.level'/, 'conf.level = 0 is rejected');
	eval { wilcox_test(\@x, edgeworth => 4) };
	like($@, qr/'edgeworth'/, 'edgeworth = 4 is rejected');
	eval { wilcox_test(\@x, tol_root => 0) };
	like($@, qr/'tol\.root'/, 'tol.root = 0 is rejected');
	# An explicit undef y is R's NULL: a one-sample test, not an error.
	my $r = wilcox_test(\@x, y => undef);
	is($r->{statistic_name}, 'V', 'y => undef means no second sample');
}

# NaN is R's NA and goes; +/-Inf stays.
{
	my $inf = 9 ** 9 ** 9;
	my $nan = $inf - $inf;
	my $with    = wilcox_test([1, 2, 3, 4, $nan, 6, 7]);
	my $without = wilcox_test([1, 2, 3, 4, 6, 7]);
	is($with->{statistic}, $without->{statistic}, 'a NaN in x is dropped (V)');
	is($with->{p_value},   $without->{p_value},   'a NaN in x is dropped (p)');
	# R: wilcox.test(c(1,2,3,4,NaN,6,7)) -> V = 21, p = 0.03125
	close_to($with->{statistic}, 21,      $TOL_STAT, 'NaN dropped: V matches R');
	close_to($with->{p_value},   0.03125, 1e-14,     'NaN dropped: p matches R');
	my $w2 = wilcox_test([1, 2, 3, 4], [3, 6, 7, $nan, 9, 3, 2, 1, 4, 4, 5]);
	my $w2ref = wilcox_test([1, 2, 3, 4], [3, 6, 7, 9, 3, 2, 1, 4, 4, 5]);
	is($w2->{p_value}, $w2ref->{p_value}, 'a NaN in y is dropped');
	# The string forms perl accepts as numbers behave the same way.
	is(wilcox_test([1, 2, 3, 4, 'NaN', 6, 7])->{p_value}, $without->{p_value},
		"the string 'NaN' is dropped as well");
}

# ===========================================================================
# 9. Deliberate divergences from R, asserted so that changing one is a choice
# ===========================================================================

# R's `correct` is an integer 0:3 in which numeric 0 keeps the continuity
# correction and only FALSE removes it.  Here 0 is false, as everywhere else
# in this module, and the Edgeworth terms live under `edgeworth`.
{
	my @x = (1.83,  0.50,  1.62,  2.48, 1.68, 1.88, 1.55, 3.06, 1.30);
	my @y = (0.878, 0.647, 0.598, 2.05, 1.06, 1.29, 1.06, 3.14, 1.29);
	my $r = wilcox_test(\@x, \@y, exact => 0, correct => 0);
	# R's wilcox.test(x, y, exact=FALSE, correct=0) gives 0.13291945818531881,
	# because to R the numeric 0 is not FALSE.  Ours matches R's correct=FALSE.
	close_to($r->{p_value}, 0.12189099149676097, 1e-12,
		'correct => 0 means no continuity correction, unlike R correct = 0');
	is($r->{method}, 'Wilcoxon rank sum test', 'correct => 0 method string');
	close_to(wilcox_test(\@x, \@y, exact => 0, correct => 1)->{p_value},
		0.13291945818531881, 1e-12, 'correct => 1 is R correct = 0 / TRUE');
}

# With exact => 0 and every observation tied the variance is zero.  R divides
# by it and reports NaN; we warn and report p = 1.  (The default path no
# longer reaches this at all: the exact test handles all-tied data.)
{
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	my $r = wilcox_test([5,5,5], [5,5,5], exact => 0);
	is($r->{p_value}, 1, 'zero variance: p = 1 where R gives NaN');
	ok(scalar @w, 'zero variance: and it says so');
	like($w[0], qr/zero variance/, 'zero variance: warning names the reason');
}

# The two-sample asymptotic interval of all-tied data has nothing to divide by
# either.  R's one-sample code warns and hands back a NaN interval at level 0;
# its two-sample code warns and then dies inside uniroot() with "missing value
# where TRUE/FALSE needed".  We give the one-sample answer in both places.
{
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	my $r = wilcox_test([(3) x 6], [(3) x 6], conf_int => 1, exact => 0);
	ok(scalar @w, 'all-tied two-sample interval: warns');
	# Two warnings arrive here: the zero-variance p-value first, then the
	# interval.  Only the second one is this block's subject.
	ok(scalar(grep { /all observations are tied/ } @w),
		'all-tied two-sample interval: warning names the reason');
	ok($r->{conf_int}[0] != $r->{conf_int}[0],
		'all-tied two-sample interval: lower limit is NaN, not an exception');
	ok($r->{conf_int}[1] != $r->{conf_int}[1],
		'all-tied two-sample interval: upper limit is NaN');
	is($r->{conf_level}, 0, 'all-tied two-sample interval: achieved level is 0');
	close_to($r->{estimate}, 0, 1e-15,
		'all-tied two-sample interval: estimate is the midrange');
}

# R's exact p-values on tied data are computed from a density it normalises
# entry by entry; we sum integer counts and divide once, so we return the
# correctly rounded double where R carries a little rounding.  Verified for
# this case against exact rational arithmetic: p is exactly 4/676039.
{
	my @x = (5, 5, 3, 3, 4, 4, 2, 5, 4, 1, 5);
	my @y = (0.6, -0.8, -0.1, 0.9, -0.0, -0.3, -1.6, -0.6, 1.6, 0.5, 1.7, 0.5);
	my $r = wilcox_test(\@x, \@y, exact => 1);
	close_to($r->{statistic}, 130, $TOL_STAT, 'tied exact rounding: W = 130');
	close_to($r->{p_value}, 4 / 676039, 1e-15,
		'tied exact rounding: p is exactly 4/676039 (R is 1.2e-11 high)');
}

done_testing();
