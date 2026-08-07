#!/usr/bin/env perl
#
# Cross-validation of fisher_test() against the two reference implementations,
# using their own test suites rather than cases invented here.
#
# Provenance of every expected value below:
#
#   * R 4.6.1 stats::fisher.test() -- the test fisher_test() is modelled on.
#     Its p-value, conditional MLE odds ratio and confidence interval.
#   * SciPy 1.17.1 scipy/stats/tests/data/fisher_exact_results_from_r.py --
#     84 (table, conf.level, alternative) cases whose p-value, conditional
#     odds ratio and CI were generated from R 3.6.2 by SciPy's own
#     generate_fisher_exact_results_from_r.R.  They are reproduced verbatim in
#     @R_CORPUS below; that they still hold under R 4.6.1 was re-checked here.
#   * SciPy 1.17.1 scipy/stats/tests/test_stats.py::TestFisherExact -- the
#     p-values in test_basic, test_precise, test_gh4130, test_large_numbers,
#     test_gh9231 and test_less_greater, which are themselves annotated
#     "results from R" upstream.
#   * R's own regression suite, tests/reg-tests-1{a,b,d,e}.R: PR#644, PR#1662,
#     PR#4688, PR#10558, PR#18336, the "exact fisher.test" case, and the
#     do.call(fisher.test, list(t44)) table from the PR#17671 entry.
#   * The examples on R's ?fisher.test man page: Job Satisfaction (r x c),
#     Convictions at conf.level = 0.99, and Mehta & Patel's 6th example.
#
# t/fisher_test.t already covers the tea-tasting 2x2, the Convictions 2x2 at
# the default conf.level, hash-of-hash input, argument validation and leak
# checking; this file deliberately does not repeat those.
#
# Where the two references disagree, fisher_test() follows R -- see the
# zero-margin and 1-row sections at the end, which record the divergence
# explicitly so a future change of mind is a deliberate one.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR 'fisher_test';

my $INF = 9**9**9;

# Tolerances.  On this build the 84 corpus cases agree with R to 5.2e-14 at
# worst on the p-value, 1.6e-14 on the odds ratio and 1.0e-14 on either CI
# bound, and the r x c p-values below to 1.0e-12; the limits here sit a couple
# of orders above that, as headroom for other NV widths rather than as room
# the current build needs.
#
# Those margins are only that good because both sides build the hypergeometric
# density the same way, out of Loader's saddle-point binomial.  Differencing
# lgamma() instead costs the back half of a large table's p-value -- SciPy's
# gh-3014 case in Case 10 came out right to seven digits that way, which is
# still inside SciPy's own rtol but nowhere near R -- so $TOL_P is deliberately
# tight enough to notice if that ever comes back.
#
# The CI is the loosest of the four on purpose.  Both R and the XS locate the
# bound with the same Brent solver at the same absolute tolerance
# (.Machine$double.eps^0.25) on the 1/ncp scale, so the agreement seen here is
# really two identical iterations landing on the same iterate.  A long-double
# or quadmath build steps through slightly different ones, and for a bound in
# the hundreds or thousands that can show well above 1e-9 -- so the CI is only
# asked to match to the precision R itself prints.
my $TOL_P   = 1e-11;   # 2x2 p-values: a sum over a hypergeometric support
my $TOL_RXC = 1e-9;    # r x c p-values: a much longer sum, in another order
my $TOL_OR  = 1e-10;   # conditional MLE odds ratio
my $TOL_CI  = 1e-4;    # confidence bounds (see above)

# Relative compare that also copes with 0 and +Inf.
sub close_to {
	my ($got, $exp, $name, $rel) = @_;
	$rel //= $TOL_P;
	if ($exp == $INF)  { return is($got, $INF, $name) }
	if ($got == $INF)  { return ok(0, "$name (got Inf, expected $exp)") }
	if ($exp == 0) {
		my $ok = ok(abs($got) < 1e-12, $name);
		diag("got=$got expected exactly 0") unless $ok;
		return $ok;
	}
	my $err = abs($got - $exp) / abs($exp);
	ok($err < $rel, $name) or diag("got=$got expected=$exp rel_err=$err tol=$rel");
}

sub tbl { my $t = shift; join ',', map { @$_ } @$t }

# ---------------------------------------------------------------------------
# Case 1: SciPy's R-generated corpus, in full.
#
# Fourteen 2x2 tables x conf.level in (0.95, 0.99) x alternative in
# (two.sided, less, greater) = 84 cases, each pinning four numbers.  This is
# the broadest single check of the 2x2 path: it exercises the conditional MLE
# at both boundaries (odds ratio 0 and Inf), the one-sided CI bounds that are
# fixed at 0 / Inf, tables large enough that a naive 1-p tail loses all its
# digits ([[200,7],[8,300]] has p = 2e-122), and the conf.level plumbing.
# ---------------------------------------------------------------------------
my @R_CORPUS = (
	# [ table, conf.level, alternative, p, conditional OR, CI lower, CI upper ]
	[ [[100,2],[1000,5]], 0.95, 'two.sided', 0.1300759363430016, 0.25055839934223, 0.04035202926536294, 2.662846672960251 ],
	[ [[2,7],[8,2]], 0.95, 'two.sided', 0.02301413756522116, 0.0858623513573622, 0.004668988338943325, 0.895792956493601 ],
	[ [[5,1],[10,10]], 0.95, 'two.sided', 0.1973244147157191, 4.725646047336587, 0.4153910882532168, 259.2593661129417 ],
	[ [[5,15],[20,20]], 0.95, 'two.sided', 0.09580440012477633, 0.3394396617440851, 0.0805633752638581, 1.22704788545557 ],
	[ [[5,16],[16,25]], 0.95, 'two.sided', 0.2697004098849359, 0.4937791394540491, 0.1176691231650079, 1.787463657995973 ],
	[ [[10,5],[10,1]], 0.95, 'two.sided', 0.1973244147157192, 0.2116112781158479, 0.003857141267422399, 2.407369893767229 ],
	[ [[10,5],[10,0]], 0.95, 'two.sided', 0.06126482213438735, 0, 0, 1.451643573543705 ],
	[ [[5,0],[1,4]], 0.95, 'two.sided', 0.04761904761904762, $INF, 1.024822256141754, $INF ],
	[ [[0,5],[1,4]], 0.95, 'two.sided', 1, 0, 0, 39.00054996869288 ],
	[ [[5,1],[0,4]], 0.95, 'two.sided', 0.04761904761904761, $INF, 1.024822256141754, $INF ],
	[ [[0,1],[3,2]], 0.95, 'two.sided', 1, 0, 0, 39.00054996869287 ],
	[ [[200,7],[8,300]], 0.95, 'two.sided', 2.005657880389071e-122, 977.7866978606228, 349.2595113327733, 3630.382605689872 ],
	[ [[28,21],[6,1957]], 0.95, 'two.sided', 5.728437460831947e-44, 425.2403028434684, 152.4166024390096, 1425.700792178893 ],
	[ [[190,800],[200,900]], 0.95, 'two.sided', 0.574111858126088, 1.068697577856801, 0.8520462587912048, 1.340148950273938 ],
	[ [[100,2],[1000,5]], 0.99, 'two.sided', 0.1300759363430016, 0.25055839934223, 0.02502345007115455, 6.304424772117853 ],
	[ [[2,7],[8,2]], 0.99, 'two.sided', 0.02301413756522116, 0.0858623513573622, 0.001923034001462487, 1.53670836950172 ],
	[ [[5,1],[10,10]], 0.99, 'two.sided', 0.1973244147157191, 4.725646047336587, 0.2397970951413721, 1291.342011095509 ],
	[ [[5,15],[20,20]], 0.99, 'two.sided', 0.09580440012477633, 0.3394396617440851, 0.05127576113762925, 1.717176678806983 ],
	[ [[5,16],[16,25]], 0.99, 'two.sided', 0.2697004098849359, 0.4937791394540491, 0.07498546954483619, 2.506969905199901 ],
	[ [[10,5],[10,1]], 0.99, 'two.sided', 0.1973244147157192, 0.2116112781158479, 0.0007743881879531337, 4.170192301163831 ],
	[ [[10,5],[10,0]], 0.99, 'two.sided', 0.06126482213438735, 0, 0, 2.642491011905582 ],
	[ [[5,0],[1,4]], 0.99, 'two.sided', 0.04761904761904762, $INF, 0.496935393325443, $INF ],
	[ [[0,5],[1,4]], 0.99, 'two.sided', 1, 0, 0, 198.019801980198 ],
	[ [[5,1],[0,4]], 0.99, 'two.sided', 0.04761904761904761, $INF, 0.496935393325443, $INF ],
	[ [[0,1],[3,2]], 0.99, 'two.sided', 1, 0, 0, 198.019801980198 ],
	[ [[200,7],[8,300]], 0.99, 'two.sided', 2.005657880389071e-122, 977.7866978606228, 270.0334165523604, 5461.333333326708 ],
	[ [[28,21],[6,1957]], 0.99, 'two.sided', 5.728437460831947e-44, 425.2403028434684, 116.7944750275836, 1931.995993191814 ],
	[ [[190,800],[200,900]], 0.99, 'two.sided', 0.574111858126088, 1.068697577856801, 0.7949398282935892, 1.436229679394333 ],
	[ [[100,2],[1000,5]], 0.95, 'less', 0.1300759363430016, 0.25055839934223, 0, 1.797867027270803 ],
	[ [[2,7],[8,2]], 0.95, 'less', 0.0185217259520665, 0.0858623513573622, 0, 0.6785254803404526 ],
	[ [[5,1],[10,10]], 0.95, 'less', 0.9782608695652173, 4.725646047336587, 0, 127.8497388102893 ],
	[ [[5,15],[20,20]], 0.95, 'less', 0.05625775074399956, 0.3394396617440851, 0, 1.032332939718425 ],
	[ [[5,16],[16,25]], 0.95, 'less', 0.1808979350599346, 0.4937791394540491, 0, 1.502407513296985 ],
	[ [[10,5],[10,1]], 0.95, 'less', 0.1652173913043479, 0.2116112781158479, 0, 1.820421051562392 ],
	[ [[10,5],[10,0]], 0.95, 'less', 0.0565217391304348, 0, 0, 1.06224603077045 ],
	[ [[5,0],[1,4]], 0.95, 'less', 1, $INF, 0, $INF ],
	[ [[0,5],[1,4]], 0.95, 'less', 0.5, 0, 0, 19.00192394479939 ],
	[ [[5,1],[0,4]], 0.95, 'less', 1, $INF, 0, $INF ],
	[ [[0,1],[3,2]], 0.95, 'less', 0.4999999999999999, 0, 0, 19.00192394479939 ],
	[ [[200,7],[8,300]], 0.95, 'less', 1, 977.7866978606228, 0, 3045.460216525746 ],
	[ [[28,21],[6,1957]], 0.95, 'less', 1, 425.2403028434684, 0, 1186.440170942579 ],
	[ [[190,800],[200,900]], 0.95, 'less', 0.7416227010368963, 1.068697577856801, 0, 1.293551891610822 ],
	[ [[100,2],[1000,5]], 0.99, 'less', 0.1300759363430016, 0.25055839934223, 0, 4.375946050832565 ],
	[ [[2,7],[8,2]], 0.99, 'less', 0.0185217259520665, 0.0858623513573622, 0, 1.235282118191202 ],
	[ [[5,1],[10,10]], 0.99, 'less', 0.9782608695652173, 4.725646047336587, 0, 657.2063583945989 ],
	[ [[5,15],[20,20]], 0.99, 'less', 0.05625775074399956, 0.3394396617440851, 0, 1.498867660683128 ],
	[ [[5,16],[16,25]], 0.99, 'less', 0.1808979350599346, 0.4937791394540491, 0, 2.186159386716762 ],
	[ [[10,5],[10,1]], 0.99, 'less', 0.1652173913043479, 0.2116112781158479, 0, 3.335351451901569 ],
	[ [[10,5],[10,0]], 0.99, 'less', 0.0565217391304348, 0, 0, 2.075407697450433 ],
	[ [[5,0],[1,4]], 0.99, 'less', 1, $INF, 0, $INF ],
	[ [[0,5],[1,4]], 0.99, 'less', 0.5, 0, 0, 99.00009507969122 ],
	[ [[5,1],[0,4]], 0.99, 'less', 1, $INF, 0, $INF ],
	[ [[0,1],[3,2]], 0.99, 'less', 0.4999999999999999, 0, 0, 99.00009507969123 ],
	[ [[200,7],[8,300]], 0.99, 'less', 1, 977.7866978606228, 0, 4503.078257659934 ],
	[ [[28,21],[6,1957]], 0.99, 'less', 1, 425.2403028434684, 0, 1811.766127544222 ],
	[ [[190,800],[200,900]], 0.99, 'less', 0.7416227010368963, 1.068697577856801, 0, 1.396522811516685 ],
	[ [[100,2],[1000,5]], 0.95, 'greater', 0.979790445314723, 0.25055839934223, 0.05119649909830196, $INF ],
	[ [[2,7],[8,2]], 0.95, 'greater', 0.9990149169715733, 0.0858623513573622, 0.007163749169069961, $INF ],
	[ [[5,1],[10,10]], 0.95, 'greater', 0.1652173913043478, 4.725646047336587, 0.5493234651081089, $INF ],
	[ [[5,15],[20,20]], 0.95, 'greater', 0.9849086665340765, 0.3394396617440851, 0.1003538933958604, $INF ],
	[ [[5,16],[16,25]], 0.95, 'greater', 0.9330176609214881, 0.4937791394540491, 0.146507416280863, $INF ],
	[ [[10,5],[10,1]], 0.95, 'greater', 0.9782608695652174, 0.2116112781158479, 0.007821681994077808, $INF ],
	[ [[10,5],[10,0]], 0.95, 'greater', 1, 0, 0, $INF ],
	[ [[5,0],[1,4]], 0.95, 'greater', 0.02380952380952382, $INF, 1.487678929918272, $INF ],
	[ [[0,5],[1,4]], 0.95, 'greater', 1, 0, 0, $INF ],
	[ [[5,1],[0,4]], 0.95, 'greater', 0.0238095238095238, $INF, 1.487678929918272, $INF ],
	[ [[0,1],[3,2]], 0.95, 'greater', 1, 0, 0, $INF ],
	[ [[200,7],[8,300]], 0.95, 'greater', 2.005657880388915e-122, 977.7866978606228, 397.784359748113, $INF ],
	[ [[28,21],[6,1957]], 0.95, 'greater', 5.728437460831983e-44, 425.2403028434684, 174.7148056880929, $INF ],
	[ [[190,800],[200,900]], 0.95, 'greater', 0.2959825901308897, 1.068697577856801, 0.8828406663967776, $INF ],
	[ [[100,2],[1000,5]], 0.99, 'greater', 0.979790445314723, 0.25055839934223, 0.03045407081240429, $INF ],
	[ [[2,7],[8,2]], 0.99, 'greater', 0.9990149169715733, 0.0858623513573622, 0.002768053063547901, $INF ],
	[ [[5,1],[10,10]], 0.99, 'greater', 0.1652173913043478, 4.725646047336587, 0.2998184792279909, $INF ],
	[ [[5,15],[20,20]], 0.99, 'greater', 0.9849086665340765, 0.3394396617440851, 0.06180414342643172, $INF ],
	[ [[5,16],[16,25]], 0.99, 'greater', 0.9330176609214881, 0.4937791394540491, 0.09037094010066403, $INF ],
	[ [[10,5],[10,1]], 0.99, 'greater', 0.9782608695652174, 0.2116112781158479, 0.001521592095430679, $INF ],
	[ [[10,5],[10,0]], 0.99, 'greater', 1, 0, 0, $INF ],
	[ [[5,0],[1,4]], 0.99, 'greater', 0.02380952380952382, $INF, 0.6661157890359722, $INF ],
	[ [[0,5],[1,4]], 0.99, 'greater', 1, 0, 0, $INF ],
	[ [[5,1],[0,4]], 0.99, 'greater', 0.0238095238095238, $INF, 0.6661157890359725, $INF ],
	[ [[0,1],[3,2]], 0.99, 'greater', 1, 0, 0, $INF ],
	[ [[200,7],[8,300]], 0.99, 'greater', 2.005657880388915e-122, 977.7866978606228, 297.9619252357688, $INF ],
	[ [[28,21],[6,1957]], 0.99, 'greater', 5.728437460831983e-44, 425.2403028434684, 130.3213490295859, $INF ],
	[ [[190,800],[200,900]], 0.99, 'greater', 0.2959825901308897, 1.068697577856801, 0.8176272148267533, $INF ],
);

for my $c (@R_CORPUS) {
	my ($t, $conf, $alt, $p, $or, $lo, $hi) = @$c;
	my $lbl = sprintf '[%s] conf=%s %s', tbl($t), $conf, $alt;
	my $r = fisher_test($t, conf_level => $conf, alternative => $alt);
	close_to($r->{p_value},                $p,  "C1 $lbl p-value",   $TOL_P);
	close_to($r->{estimate}{"odds ratio"}, $or, "C1 $lbl odds ratio", $TOL_OR);
	close_to($r->{conf_int}[0],            $lo, "C1 $lbl CI lower",  $TOL_CI);
	close_to($r->{conf_int}[1],            $hi, "C1 $lbl CI upper",  $TOL_CI);
	is($r->{conf_level}, $conf, "C1 $lbl conf_level echoed");
	is($r->{alternative}, $alt, "C1 $lbl alternative echoed");
}

# ---------------------------------------------------------------------------
# Case 2: SciPy TestFisherExact::test_basic and ::test_precise.
#
# The tables not already in the corpus above.  test_precise asks for 11
# decimal places against R; that is comfortably inside $TOL_P here.
# ---------------------------------------------------------------------------
{
	# [table, p, note]  -- p from R 4.6.1, printed at 17 significant digits.
	my @cases = (
		[ [[14500,20000],[30000,40000]], 0.011055117704594117, 'test_basic, N = 104500' ],
		[ [[5,16],[20,25]],              0.1725864953812995,   'test_basic' ],
		[ [[0,2],[6,4]],                 0.45454545454545453,  'test_basic, zero cell' ],
		[ [[5,15],[20,20]],              0.09580440012477633,  'test_basic' ],
		[ [[10,5],[10,1]],               0.1973244147157192,   'test_precise' ],
		[ [[10,5],[10,0]],               0.06126482213438735,  'test_precise, OR 0' ],
		[ [[5,0],[1,4]],                 0.04761904761904762,  'test_precise, OR Inf' ],
		[ [[0,5],[1,4]],                 1,                    'test_precise, p exactly 1' ],
		[ [[5,1],[0,4]],                 0.04761904761904761,  'test_precise, OR Inf' ],
		[ [[0,1],[3,2]],                 1,                    'test_precise, p exactly 1' ],
	);
	for my $c (@cases) {
		my ($t, $p, $note) = @$c;
		close_to(fisher_test($t)->{p_value}, $p, "C2 [".tbl($t)."] two-sided p ($note)");
	}
	# test_basic also pins the sample odds ratio of [[2,7],[8,2]] at 4/56.
	# fisher_test() reports R's conditional MLE instead, which is a different
	# estimator: 0.0859 rather than 0.0714.  Both are checked so that the two
	# never get confused for one another.
	my $r = fisher_test([[2,7],[8,2]]);
	close_to($r->{estimate}{"odds ratio"}, 0.0858623513573622,
		 "C2 [[2,7],[8,2]] reports R's conditional MLE", $TOL_OR);
	ok(abs($r->{estimate}{"odds ratio"} - 4/56) > 1e-3,
	   "C2 [[2,7],[8,2]] conditional MLE is not SciPy's sample odds ratio (4/56)");
}

# ---------------------------------------------------------------------------
# Case 3: SciPy TestFisherExact::test_gh4130.
#
# gh-4130 was a fudge factor of 1e-4 used to decide whether two tables were
# "equally probable" when accumulating the two-sided tail; it swept in tables
# it should not have.  The XS uses a relative 1e-7 instead, so these three
# hold.  [[22,0],[0,102]] and [[94,48],[3577,16988]] additionally check that
# a p-value far below the smallest normal double still comes out right.
# ---------------------------------------------------------------------------
close_to(fisher_test([[6,37],[108,200]])->{p_value},   0.0050926977481257915,  'C3 gh4130 [[6,37],[108,200]]');
close_to(fisher_test([[22,0],[0,102]])->{p_value},     7.1750667862445468e-25, 'C3 gh4130 [[22,0],[0,102]]');
close_to(fisher_test([[94,48],[3577,16988]])->{p_value}, 2.0693563409938471e-37, 'C3 gh4130 [[94,48],[3577,16988]]');

# ---------------------------------------------------------------------------
# Case 4: SciPy TestFisherExact::test_large_numbers and ::test_gh9231.
#
# test_large_numbers is SciPy's regression test for gh-1401 (the hypergeometric
# losing accuracy on large tables).  test_gh9231's table has a margin of 11.5
# million and used to take SciPy minutes; its p-value is far below anything a
# tail approximation could reach, and R puts it at 6.13e-178.
# ---------------------------------------------------------------------------
close_to(fisher_test([[17704,496],[1065,75]])->{p_value}, 5.5597665725900454e-11, 'C4 large numbers, n = 75');
close_to(fisher_test([[17704,496],[1065,76]])->{p_value}, 2.6656847911317412e-11, 'C4 large numbers, n = 76');
close_to(fisher_test([[17704,496],[1065,77]])->{p_value}, 1.3632030244794552e-11, 'C4 large numbers, n = 77');
close_to(fisher_test([[18000,80000],[20000,90000]])->{p_value}, 0.27514817040628897, 'C4 large numbers, N = 208000');
{
	my $r = fisher_test([[5829225,5692693],[5760959,5760959]]);
	close_to($r->{p_value}, 6.1262127126238397e-178, 'C4 gh9231 p-value (N = 23 million)');
	close_to($r->{estimate}{"odds ratio"}, 1.0239924983807678, 'C4 gh9231 odds ratio', $TOL_OR);
}

# ---------------------------------------------------------------------------
# Case 5: SciPy TestFisherExact::test_less_greater.
#
# Four tables checked against R plus five whose one-sided p-values are exact
# rationals, which is where SciPy's ticket #1568 (a one-sided tail summed from
# the wrong end) showed up.
# ---------------------------------------------------------------------------
{
	my @cases = (
		[ [[2,7],[8,2]],       0.018521725952066501, 0.9990149169715733    ],
		[ [[200,7],[8,300]],   1.0,                  2.0056578803889148e-122 ],
		[ [[28,21],[6,1957]],  1.0,                  5.7284374608319831e-44  ],
		[ [[190,800],[200,900]], 0.7416227010368963, 0.2959825901308897    ],
		[ [[0,2],[3,0]],       1/10,                 1.0                   ],
		[ [[1,1],[2,1]],       7/10,                 9/10                  ],
		[ [[2,0],[1,2]],       1.0,                  3/10                  ],
		[ [[0,1],[2,3]],       2/3,                  1.0                   ],
		[ [[1,0],[1,4]],       1.0,                  1/3                   ],
	);
	for my $c (@cases) {
		my ($t, $less, $greater) = @$c;
		close_to(fisher_test($t, alternative => 'less')->{p_value},
			 $less,    "C5 [".tbl($t)."] alternative=less");
		close_to(fisher_test($t, alternative => 'greater')->{p_value},
			 $greater, "C5 [".tbl($t)."] alternative=greater");
	}
}

# ---------------------------------------------------------------------------
# Case 6: R man-page examples that t/fisher_test.t does not already cover.
#
# ?fisher.test runs Convictions at two conf.levels; the 0.95 pair is in
# t/fisher_test.t, so only 0.99 is new here.  Job Satisfaction is R's own r x c
# example, and its documented answer (0.7827) is the check.
# ---------------------------------------------------------------------------
{
	my $r = fisher_test([[2,15],[10,3]], conf_level => 0.99);
	close_to($r->{p_value},                0.0005367241191434356, 'C6 Convictions p-value');
	close_to($r->{estimate}{"odds ratio"}, 0.046936608827698879,  'C6 Convictions odds ratio', $TOL_OR);
	close_to($r->{conf_int}[0],            0.001386332871545104,  'C6 Convictions 99% CI lower', $TOL_CI);
	close_to($r->{conf_int}[1],            0.57885164459479332,   'C6 Convictions 99% CI upper', $TOL_CI);
	is($r->{conf_level}, 0.99, 'C6 Convictions conf_level 0.99 echoed');
}
{
	# Agresti (2002, p. 57) Job Satisfaction, a 4x4 documented as "0.7827".
	my $job = [[1,3,10,6],[2,3,10,7],[1,6,14,12],[0,1,9,11]];
	my $r = fisher_test($job);
	close_to($r->{p_value}, 0.78268493896563884, 'C6 Job Satisfaction 4x4 p-value', $TOL_RXC);
	is(sprintf('%.4f', $r->{p_value}), '0.7827', 'C6 Job Satisfaction matches the documented 0.7827');
	ok(!exists $r->{estimate}, 'C6 no odds ratio for a 4x4');
}

# ---------------------------------------------------------------------------
# Case 7: R's own regression suite, tests/reg-tests-1{a,b,d}.R.
# ---------------------------------------------------------------------------

# PR#644: 19x2, "crash using fisher.test on Windows" (it was not just Windows).
{
	my $pr644 = [[2,1],[2,1],[4,0],[8,0],[6,0],[0,0],[1,0],[1,1],[7,1],[8,2],
		     [1,0],[3,1],[1,1],[3,0],[7,2],[4,1],[2,0],[2,0],[2,0]];
	close_to(fisher_test($pr644)->{p_value}, 0.71781378237770943,
		 'C7 PR#644 19x2 p-value', $TOL_RXC);
}

# PR#1662: "fisher.test with total one", which crashed R <= 1.5.0.  Every
# margin but one is zero, so the observed table is the only one there is.
{
	my $r = fisher_test([[0,0],[0,0],[0,0],[0,1]]);
	is($r->{p_value}, 1, 'C7 PR#1662 4x2 table with total 1 gives p = 1');
}

# PR#10558: "fisher.test with extreme degeneracy".  R's comment records the
# true value as 1/60; 2.6.1-patched simulated about 0.0005 for it.
close_to(fisher_test([[1,0,0],[0,2,0],[0,0,3]])->{p_value}, 1/60,
	 'C7 PR#10558 diag(1:3) p-value is exactly 1/60', $TOL_RXC);

# reg-tests-1b.R, '"exact" fisher.test': R < 2.11.0 returned 1 + 1.17e-13 for
# this table, so the assertion upstream is that p stays a probability.  Here
# the two rows are identical, which makes the observed table the modal one and
# the p-value exactly 1.
{
	my $p = fisher_test([[14,29,16],[14,29,16]])->{p_value};
	ok($p >= 0 && $p <= 1, 'C7 identical-rows 2x3 p-value stays in [0,1]');
	close_to($p, 1, 'C7 identical-rows 2x3 p-value is 1', $TOL_RXC);
}

# reg-tests-1d.R (PR#17671): fisher.test on set.seed(7)'s 4x4 sample table.
close_to(fisher_test([[1,2,1,0],[4,3,1,6],[2,6,3,5],[4,3,3,6]])->{p_value},
	 0.73010293537427828, 'C7 PR#17671 t44 4x4 p-value', $TOL_RXC);

# ---------------------------------------------------------------------------
# Case 8: tables that are too big to enumerate.
#
# R refuses two of these outright, and the point of the R entries is that it
# does so instead of returning nonsense or dying:
#
#   PR#4688  4x3, N = 16442 -- R gives "FEXACT error 501", and used to report
#            p.value = Inf.  fisher_test() has to reach its own limit and say
#            so; before the enumeration counted its interior nodes this table
#            ran for over five minutes without either finishing or stopping.
#   MP6      Mehta & Patel's 6th example, 5x7.  R computes 0.0392896 with the
#            network algorithm; plain enumeration cannot reach it (measured at
#            well over 10 minutes with the node cap lifted), so fisher_test()
#            declines rather than grinding.
#
# Both must fail the same way: promptly, and with a message that names the
# shape rather than leaking an internal error.
# ---------------------------------------------------------------------------
for my $c ([ 'PR#4688 4x3', [[2121,4700,6234],[100,216,2461],[27,67,502],[0,0,14]], qr/4x3/ ],
	   [ 'Mehta & Patel 5x7', [[1,2,2,1,1,0,1],[2,0,0,2,3,0,0],[0,1,1,1,2,7,3],
				   [1,1,2,0,0,0,1],[0,1,1,1,1,0,0]], qr/5x7/ ]) {
	my ($name, $t, $shape) = @$c;
	my $started = time;
	my $r = eval { fisher_test($t) };
	my $took = time - $started;
	ok(!defined $r, "C8 $name is refused, not answered wrongly");
	like($@, qr/too large for exact enumeration/, "C8 $name croaks with a usable message");
	like($@, $shape, "C8 $name names the table shape");
	cmp_ok($took, '<', 60, "C8 $name gives up promptly (${took}s)");
}

# PR#18336, the 6x6 "too full" table that segfaulted R <= 4.2.0 and that R
# 4.6.1 still declines with "hash key 5e+09 > INT_MAX".  Enumeration handles
# it: the answer below agrees with R's own Monte-Carlo fallback
# (fisher.test(d, simulate.p.value = TRUE, B = 2e6) = 0.63224) to within its
# sampling error, so this is a case where fisher_test() answers and R does not.
{
	my $d = [[1,0,5,2,1,90],[2,1,0,2,3,89],[0,0,0,1,0,14],
		 [0,0,0,0,0,5],[0,0,0,0,0,2],[0,0,0,0,0,2]];
	my $p = fisher_test($d)->{p_value};
	ok($p > 0 && $p <= 1, 'C8 PR#18336 6x6 returns a probability where R errors');
	ok(abs($p - 0.6322381839) < 2e-3,
	   'C8 PR#18336 6x6 p-value agrees with R simulate.p.value (B = 2e6)')
		or diag("got=$p, R's 2e6-replicate estimate = 0.6322381839");
}

# ---------------------------------------------------------------------------
# Case 9: a zero row or a zero column.  SciPy's test_row_or_col_zero expects
# p = 1 with a NaN odds ratio; R returns p = 1 with an odds ratio of 0 and a
# CI of (0, Inf).  fisher_test() follows R.
# ---------------------------------------------------------------------------
for my $t ([[0,0],[5,10]], [[5,10],[0,0]], [[0,5],[0,10]], [[5,0],[10,0]]) {
	my $r = fisher_test($t);
	is($r->{p_value}, 1, "C9 [".tbl($t)."] empty margin gives p = 1");
	is($r->{estimate}{"odds ratio"}, 0,    "C9 [".tbl($t)."] odds ratio 0, as in R (SciPy says NaN)");
	is($r->{conf_int}[0], 0,               "C9 [".tbl($t)."] CI lower 0");
	is($r->{conf_int}[1], $INF,            "C9 [".tbl($t)."] CI upper Inf");
}

# ---------------------------------------------------------------------------
# Case 10: SciPy edge cases where fisher_test() deliberately behaves otherwise.
# ---------------------------------------------------------------------------

# test_gh3014: a table with one huge cell used to raise; it must simply work.
{
	my $r = fisher_test([[1,2],[9,84419233]]);
	close_to($r->{p_value}, 3.553691673228909e-07, 'C10 gh3014 lopsided table has a p-value');
	close_to($r->{estimate}{"odds ratio"}, 12287.998558770239, 'C10 gh3014 odds ratio', $TOL_OR);
	# R stops the upper bound at 2^52 here rather than reporting Inf.
	close_to($r->{conf_int}[1], 4503599627370496, 'C10 gh3014 CI upper matches R', $TOL_CI);
}

# test_input_validation_edge_cases_rxc: SciPy returns (1, 1) for a table with a
# single row or a single column.  R rejects those ("'x' must have at least 2
# rows and columns") and so does fisher_test(); test_raises' non-2D input is
# rejected for the same reason.
eval { fisher_test([[1,2,3]]) };
ok($@, 'C10 single-row table croaks (R semantics, not SciPy\'s p = 1)');
eval { fisher_test([[1],[2],[3]]) };
ok($@, 'C10 single-column table croaks (R semantics, not SciPy\'s p = 1)');
eval { fisher_test([[0,0,0],[0,0,0]]) };
ok($@, 'C10 all-zero table croaks rather than returning p = 1');
eval { fisher_test([0,1,2,3,4,5]) };
ok($@, 'C10 one-dimensional input croaks');

done_testing();
