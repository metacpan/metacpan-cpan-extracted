#!/usr/bin/env perl
#
# Cross-validation of oneway_test() against the reference implementations.
#
# Every expected value below was produced by one of:
#
#   * R 4.6.1 stats::oneway.test(y ~ g, var.equal = FALSE / TRUE) -- the test
#     oneway_test() is modelled on; statistic, num df, denom df and p-value.
#   * R 4.6.1 anova(aov(y ~ g)) -- the Sum Sq / Mean Sq columns, for the
#     equal-variance branch (oneway.test itself reports no sums of squares).
#   * statsmodels.stats.oneway.anova_oneway(use_var="unequal") and
#     scipy.stats.f_oneway, used as an independent third opinion while these
#     cases were built; they agree with R everywhere they are both defined.
#   * scipy.stats.f.sf() for tail p-values, which is where the naive
#     1 - pf(F, df1, df2) formulation used to lose everything below ~1e-16.
#
# The data sets are R's own built-ins (chickwts, InsectSprays, PlantGrowth,
# iris, ToothGrowth, mtcars, warpbreaks, sleep, airquality, CO2, esoph,
# OrchardSprays, faithful) plus hand-built numerical edge cases.

require 5.010;
use warnings FATAL => 'all';
use strict;
use Stats::LikeR;
use Test::Exception;
use Test::More;

my $INF = 9**9**9;
my $NAN = $INF - $INF;

sub is_nan { my $x = shift; return !defined($x) ? 0 : ($x != $x); }

# How far the statistic itself may legitimately move between builds.
#
# Forming a within-group sum of squares subtracts the group mean, so a case whose
# residual variation is tiny next to the data's magnitude loses digits to
# cancellation -- and F, being 1/ss_within, inherits that. The standard bound is
# the cancellation ratio ||y|| / ||residual||, carried in each case below as
# `cond`, times the machine epsilon. `huge_separation` has cond = 7.5e5, so its F
# is only good to about 8e-10 relative, and builds land in different places inside
# that: on a long-double NV perl ($Config{nvtype} eq 'long double', which 5.12.5
# is) the literals round differently and the cancellation starts from a different
# place, so its F differs from an ordinary double build's by 2.4e-11 on the same
# source data. A flat tolerance either rejects a correct build or is too slack for
# the 30 well-conditioned cases, so both tolerances below are derived per case
# instead. Well-conditioned cases keep the 1e-11 floor.
sub stat_tol {
	my ($cond) = @_;
	my $t = ($cond || 1) * 1e-15;
	return $t > 1e-11 ? $t : 1e-11;
}
# The p-value amplifies the statistic's error: for the upper F tail
# p ~ F^(-df2/2), so d(log p) = (df2/2) * d(log F).
sub tail_tol {
	my ($cond, $df2) = @_;
	my $amp = (defined $df2 && $df2 == $df2 && $df2 > 2) ? $df2 / 2 : 1;
	my $t = stat_tol($cond) * $amp;
	return $t > 1e-11 ? $t : 1e-11;
}

# Relative-error comparison that also handles NaN and +/-Inf, since a
# zero-variance group legitimately produces both.  $atol is an absolute floor,
# used only where the exact answer is 0 and a relative error is meaningless.
sub rel_ok {
	my ($got, $exp, $lbl, $tol, $atol) = @_;
	$tol  = 1e-11 unless defined $tol;
	$atol = 0     unless defined $atol;
	if (is_nan($exp)) { return ok(is_nan($got), "$lbl: NaN"); }
	if (is_nan($got)) { fail("$lbl: got NaN, wanted $exp"); return 0; }
	if ($exp == $INF || $exp == -$INF) { return is($got, $exp, "$lbl: infinite"); }
	my $diff = abs($got - $exp);
	if ($atol && $diff <= $atol) { pass("$lbl (abs err $diff <= $atol)"); return 1 }
	my $scale = abs($got) > abs($exp) ? abs($got) : abs($exp);
	my $err   = $scale < 1e-300 ? $diff : $diff / $scale;
	if ($err <= $tol) { pass("$lbl (rel err $err <= $tol)"); return 1 }
	fail($lbl);
	diag("         got: $got\n    expected: $exp\n     rel err: $err");
	return 0;
}

# ---------------------------------------------------------------------------
# name => [ [group => \@obs, ...], welch, classic, aov ]
# ---------------------------------------------------------------------------
my @CASES = (
	# ---- pod_example (synthetic) ----
	{
		name   => 'pod_example',
		cond   => 4.33018,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'ctrl' => [1, 1, 1, 0, 0, 0],
			'yield' => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
		],
		welch => { F => 177.504798464491, df1 => 1, df2 => 9.81767348326473, p => 1.31343255150314e-07 },
		classic => { F => 177.504798464491, df1 => 1, df2 => 10, p => 1.08622654741839e-07 },
		aov => { ssb => 61.6533333333333, ssw => 3.47333333333334, msb => 61.6533333333333, msw => 0.347333333333334 },
	},
	# ---- three_unequal_n (synthetic) ----
	{
		name   => 'three_unequal_n',
		cond   => 2.60553,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'a' => [1, 2, 3, 4, 5],
			'b' => [2, 4, 6, 8],
			'c' => [10, 11, 12, 13, 14, 15, 16],
		],
		welch => { F => 40.4021617212195, df1 => 2, df2 => 7.10125412541254, p => 0.000131915531432298 },
		classic => { F => 37.6271551724138, df1 => 2, df2 => 13, p => 3.92056152848904e-06 },
		aov => { ssb => 335.75, ssw => 58, msb => 167.875, msw => 4.46153846153846 },
	},
	# ---- equal_means (synthetic) ----
	{
		name   => 'equal_means',
		cond   => 1,   # ||y|| / ||residual||: digits lost to cancellation
		atol   => 1e-20,
		groups => [
			'a' => [1, 2, 3, 4, 5],
			'b' => [0, 1.5, 3, 4.5, 6],
			'c' => [-2, 0, 3, 6, 8],
		],
		welch => { F => 0, df1 => 2, df2 => 7.20072714990256, p => 1 },
		classic => { F => 0, df1 => 2, df2 => 12, p => 1 },
		# aov omitted: R's QR-based anova(aov()) is the less accurate side here
	},
	# ---- huge_separation (synthetic) ----
	{
		name   => 'huge_separation',
		cond   => 753778,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'a' => [0, 0.001, -0.001, 0.0005, 0],
			'b' => [1000, 1000.001, 999.999, 1000.0005, 1000],
		],
		welch => { F => 4545454545562.03, df1 => 1, df2 => 8, p => 2.6236671997352e-48 },
		classic => { F => 4545454545562.03, df1 => 1, df2 => 8, p => 2.6236671997352e-48 },
		# aov omitted: R's QR-based anova(aov()) is the less accurate side here
	},
	# ---- n2_groups (synthetic) ----
	{
		name   => 'n2_groups',
		cond   => 3.40168,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'a' => [1, 2],
			'b' => [5, 7],
			'c' => [10, 14],
		],
		welch => { F => 13.5762711864407, df1 => 2, df2 => 1.64705882352941, p => 0.09475860126707 },
		classic => { F => 15.8571428571429, df1 => 2, df2 => 3, p => 0.0254050194478081 },
		aov => { ssb => 111, ssw => 10.5, msb => 55.5, msw => 3.5 },
	},
	# ---- negative_values (synthetic) ----
	{
		name   => 'negative_values',
		cond   => 11.9307,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'a' => [-5, -4, -6, -5.5],
			'b' => [-1, -2, -1.5, -0.5],
			'c' => [-20, -21, -19, -20.5],
		],
		welch => { F => 574.680923866553, df1 => 2, df2 => 5.88235294117647, p => 1.80103194678516e-07 },
		classic => { F => 636.033333333333, df1 => 2, df2 => 9, p => 2.04182493404555e-10 },
		aov => { ssb => 795.041666666667, ssw => 5.625, msb => 397.520833333333, msw => 0.625 },
	},
	# ---- large_magnitude (synthetic) ----
	{
		name   => 'large_magnitude',
		cond   => 4.58258,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'a' => [100000000, 100000001, 100000002, 100000003],
			'b' => [100000010, 100000011, 100000012, 100000013],
		],
		welch => { F => 120, df1 => 1, df2 => 6, p => 3.43640280761215e-05 },
		classic => { F => 120, df1 => 1, df2 => 6, p => 3.43640280761215e-05 },
		# aov omitted: R's QR-based anova(aov()) is the less accurate side here
	},
	# ---- small_magnitude (synthetic) ----
	{
		name   => 'small_magnitude',
		cond   => 2.04939,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'a' => [1e-08, 2e-08, 3e-08, 4e-08],
			'b' => [5e-08, 6e-08, 7e-08, 8e-08],
		],
		welch => { F => 19.2, df1 => 1, df2 => 6, p => 0.00465921494399393 },
		classic => { F => 19.2, df1 => 1, df2 => 6, p => 0.00465921494399394 },
		aov => { ssb => 3.2e-15, ssw => 1e-15, msb => 3.2e-15, msw => 1.66666666666667e-16 },
	},
	# ---- two_group_ttest_equiv (synthetic) ----
	{
		name   => 'two_group_ttest_equiv',
		cond   => 2.10125,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'a' => [2.1, 3.4, 1.9, 2.8, 3.3, 2.2],
			'b' => [4.4, 5.1, 3.9, 4.8, 5.5],
		],
		welch => { F => 30.9770974883579, df1 => 1, df2 => 8.76222683502488, p => 0.000384448000074448 },
		classic => { F => 30.7372297177871, df1 => 1, df2 => 9, p => 0.000359139378788852 },
		aov => { ssb => 12.2960303030303, ssw => 3.60033333333333, msb => 12.2960303030303, msw => 0.400037037037037 },
	},
	# ---- outlier (synthetic) ----
	{
		name   => 'outlier',
		cond   => 1.05978,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'a' => [1, 2, 3, 4, 1000],
			'b' => [2, 3, 4, 5, 6],
		],
		welch => { F => 0.985000376874953, df1 => 1, df2 => 4.00010050124997, p => 0.377143853796016 },
		classic => { F => 0.985000376874953, df1 => 1, df2 => 8, p => 0.350033340501709 },
		aov => { ssb => 98010, ssw => 796020, msb => 98010, msw => 99502.5 },
	},
	# ---- tiny_var_ratio (synthetic) ----
	{
		name   => 'tiny_var_ratio',
		cond   => 1.37577,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'a' => [1, 1.0000001, 1.0000002, 1.0000003],
			'b' => [1, 50, 100, 150],
		],
		welch => { F => 5.35649654739186, df1 => 1, df2 => 3, p => 0.103612103134647 },
		classic => { F => 5.35649654739186, df1 => 1, df2 => 6, p => 0.0599057801913023 },
		aov => { ssb => 11026.12495545, ssw => 12350.75, msb => 11026.12495545, msw => 2058.45833333333 },
	},
	# ---- integer_data (synthetic) ----
	{
		name   => 'integer_data',
		cond   => 2.19249,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'a' => [1, 2, 3, 4, 5],
			'b' => [6, 7, 8, 9, 10],
			'c' => [2, 2, 3, 3, 4],
		],
		welch => { F => 20.0018058690745, df1 => 2, df2 => 7.22994652406417, p => 0.001130782237483 },
		classic => { F => 22.8421052631579, df1 => 2, df2 => 12, p => 8.1048644730633e-05 },
		aov => { ssb => 86.8, ssw => 22.8, msb => 43.4, msw => 1.9 },
	},
	# ---- f_below_one (synthetic) ----
	{
		name   => 'f_below_one',
		cond   => 1.00771,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'a' => [1, 5, 9, 2, 8],
			'b' => [2, 6, 3, 7, 4],
			'c' => [5, 1, 8, 3, 9],
		],
		welch => { F => 0.115814331479849, df1 => 2, df2 => 7.49101622045327, p => 0.892204540845609 },
		classic => { F => 0.0928571428571428, df1 => 2, df2 => 12, p => 0.911972052171714 },
		aov => { ssb => 1.73333333333333, ssw => 112, msb => 0.866666666666665, msw => 9.33333333333334 },
	},
	# ---- heteroscedastic (synthetic) ----
	{
		name   => 'heteroscedastic',
		cond   => 1.00845,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'a' => [0.0623137677713257, -0.0317771841982725, 0.0261990626390625, 0.0171415376022391,
              -0.275869323287356, 0.0500694726082704, 0.0864410408119228, -0.0609601472203919,
              -0.0887491778919223, 0.0736162526493201],
			'b' => [3.12541430325904, -9.74778333162596, -11.8013854765982, -2.0493924174928, 13.6109334136579,
              5.0378426840597, -1.01660922184601, 15.8646391773861, -1.67202298386797, -5.47565084723314],
			'c' => [156.334903772165, 166.773911902291, -74.1115918055178, 41.2200266044216, 115.567556009151,
              106.58385796464, 290.130291910806, 38.6031468957029, -248.633670920036, 362.156307931981,
              88.203719759913, -184.536983880851, -73.406327252627, 1.60678363303479, -57.1939312889495,
              -143.433814777297, 49.7358683500972, 50.7582700797716, -33.7050616246356,
              -45.3134732034168, 14.8021143772575, 39.5329492279259, 88.6075485125085, -45.3189587916861,
              -70.4189047364685, 242.901736149524, 58.6771076389526, -64.340504934562, -48.0434149454774,
              -12.284579052139],
		],
		welch => { F => 0.628902804839619, df1 => 2, df2 => 18.3198426346898, p => 0.544300862576203 },
		classic => { F => 0.398759357421688, df1 => 2, df2 => 47, p => 0.673401208485444 },
		aov => { ssb => 8596.12214213067, ssw => 506593.429295869, msb => 4298.06107106534, msw => 10778.5836020398 },
	},
	# ---- many_groups (synthetic) ----
	{
		name   => 'many_groups',
		cond   => 2.09565,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'g1' => [0.592511125400896, 0.699554717794561, 1.25507590544524, 0.883216123827986,
               1.13937142832755, 1.13583900273769],
			'g10' => [10.0418539041324, 11.3938340251351, 13.5808163871852, 12.2991186950425, 9.23053264723011,
                14.5731307674457, 7.44335247133544, 11.8967792474775, 11.5110760157783, 13.4923847898624,
                8.40591499568537, 12.0159825809328, 7.28914669630773, 7.9935840095994, 10.0940235855881],
			'g2' => [1.59689023369268, 3.51632613836069, 2.16797810043488, 2.01313498535972, 2.59592594975532,
               2.29531269870286, 1.89263545305899],
			'g3' => [3.32165142084067, 1.92269033008935, 3.43071037269917, 4.82922158744899, 4.24936260381293,
               3.75668593829666, 2.17286299779351, 2.4768104238531],
			'g4' => [2.21412270610847, 4.37161800294136, 5.51589922149722, 2.65554758247529, 2.88604592627377,
               5.80284084795248, 3.6225065060609, 3.28530842433552, 2.9523000148173],
			'g5' => [6.80560127993282, 4.20009814998748, 6.93487880673218, 5.99561280989253, 6.47262042622425,
               6.58729959791487, 6.18605110208206, 4.06017928998207, 5.26238815565452, 6.38326952945316],
			'g6' => [8.37813847130107, 7.18496775239733, 5.65412849141698, 6.79138140049122, 4.67034476331931,
               6.50384766960152, 9.42763204971418, 3.79663131166137, 4.80670104436202, 5.99127640293481,
               5.88172132301039],
			'g7' => [5.35472749237422, 6.30905005218348, 5.17750604058336, 10.0664304166619, 6.56638349862173,
               9.40469077929092, 5.5021836956091, 5.24167987563183, 4.06068176187716, 7.40169799364829,
               8.37205127550731, 8.36052567585142],
			'g8' => [7.17760619174682, 8.43955643974301, 5.91010502618057, 6.78498831884647, 11.9881405014394,
               6.83553819699098, 7.06532855428927, 6.71822810873381, 7.1009133350439, 6.89014852456752,
               8.54999708603366, 6.58654221905049, 8.24921022838429],
			'g9' => [10.8773008783531, 7.78524515607168, 9.6215208011922, 5.94721636694922, 10.486327080237,
               5.30167168752421, 9.2551404989235, 8.77913965685834, 9.23121533682131, 10.2479443547697,
               10.794471677197, 9.07899259152054, 11.5269463731803, 12.8177293519944],
		],
		welch => { F => 90.1962358435458, df1 => 9, df2 => 36.5532356027926, p => 3.18578458089283e-22 },
		classic => { F => 35.8016219635607, df1 => 9, df2 => 95, p => 9.20805992914193e-27 },
		aov => { ssb => 872.177835109018, ssw => 257.148170610474, msb => 96.9086483454464, msw => 2.70682284853131 },
	},
	# ---- many_small_groups (synthetic) ----
	{
		name   => 'many_small_groups',
		cond   => 1.29494,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			's1' => [1.22324832984692, 0.399814617170815, 0.788766593091852],
			's10' => [0.121079887746165, 0.9255562664983, 0.490776255825891],
			's11' => [-0.842797129891757, 0.219147843194699, 0.676274811436418],
			's12' => [0.549788954277037, 0.624719914966975, -0.279976194633652],
			's13' => [0.595814647588812, -1.16572147957457, -0.841904053239784],
			's14' => [0.387306704807836, -0.382276375380751, 2.21210325582381],
			's15' => [-0.709303750434807, 0.179689908892034, -1.94978257860664],
			's16' => [0.0589817211112815, -0.774598252740228, 0.843949929285796],
			's17' => [0.122520879269156, 1.02911835619985, 1.30939119345763],
			's18' => [0.105973679784052, 0.201471808990853, 1.61522977847016],
			's19' => [0.804797875275177, 0.79802034864887, -0.430586392819503],
			's2' => [0.853385257702089, 0.805690018408879, 1.31912803606063],
			's20' => [-0.781216881720291, 1.03423337551192, 0.352496211652312],
			's21' => [-0.0888472571754931, -0.59751254919839, 0.979595922253855],
			's22' => [1.7746134239922, -0.632692995003805, 0.821128956746176],
			's23' => [-0.638956043640915, -0.623745138871789, -1.07089381788827],
			's24' => [1.22136620527843, 0.956523540492745, 2.24382144970985],
			's25' => [-0.423015545066742, 0.950728691239983, -0.815243493023926],
			's3' => [0.644008838247929, -1.31346682271058, 0.318837554387531],
			's4' => [-0.645534953061141, -0.325102560182552, -0.355414335806171],
			's5' => [2.10394181144412, 0.487346596320969, -1.0139322238641],
			's6' => [0.323936223360221, 0.566020284002587, 0.149772523161292],
			's7' => [0.499113452856992, 0.57669991969999, -1.95290719680108],
			's8' => [0.870293010874025, 0.82854528736841, 2.07934402263357],
			's9' => [-0.259268615840398, 0.511587382696452, 1.35367467589918],
		],
		welch => { F => 3.20744879087966, df1 => 24, df2 => 17.9794799129199, p => 0.00696898142072108 },
		classic => { F => 1.41014240625048, df1 => 24, df2 => 50, p => 0.151357855200017 },
		aov => { ssb => 25.0541642875131, ssw => 37.0148258556195, msb => 1.04392351197971, msw => 0.74029651711239 },
	},
	# ---- zero_var_one_group (synthetic) ----
	{
		name   => 'zero_var_one_group',
		cond   => 1.87083,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'a' => [5, 5, 5, 5],
			'b' => [1, 2, 3, 4],
		],
		welch => { F => $NAN, df1 => 1, df2 => $NAN, p => $NAN },
		classic => { F => 15, df1 => 1, df2 => 6, p => 0.00823735414510809 },
		aov => { ssb => 12.5, ssw => 5, msb => 12.5, msw => 0.833333333333333 },
	},
	# ---- all_zero_var (synthetic) ----
	{
		name   => 'all_zero_var',
		cond   => 1,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'a' => [5, 5, 5, 5],
			'b' => [2, 2, 2, 2],
			'c' => [9, 9, 9, 9],
		],
		welch => { F => $NAN, df1 => 2, df2 => $NAN, p => $NAN },
		classic => { F => $INF, df1 => 2, df2 => 9, p => 0 },
		# aov omitted: R's QR-based anova(aov()) is the less accurate side here
	},
	# ---- all_identical (synthetic) ----
	{
		name   => 'all_identical',
		cond   => 1,   # ||y|| / ||residual||: digits lost to cancellation
		atol   => 1e-20,
		groups => [
			'a' => [3, 3, 3, 3],
			'b' => [3, 3, 3, 3],
		],
		welch => { F => $NAN, df1 => 1, df2 => $NAN, p => $NAN },
		classic => { F => $NAN, df1 => 1, df2 => 6, p => $NAN },
		# aov omitted: R's QR-based anova(aov()) is the less accurate side here
	},
	# ---- PlantGrowth (R built-in data set) ----
	{
		name   => 'PlantGrowth',
		cond   => 1.16575,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'ctrl' => [4.17, 5.58, 5.18, 6.11, 4.5, 4.61, 5.17, 4.53, 5.33, 5.14],
			'trt1' => [4.81, 4.17, 4.41, 3.59, 5.87, 3.83, 6.03, 4.89, 4.32, 4.69],
			'trt2' => [6.31, 5.12, 5.54, 5.5, 5.37, 5.29, 4.92, 6.15, 5.8, 5.26],
		],
		welch => { F => 5.18097240811319, df1 => 2, df2 => 17.1284186166441, p => 0.01739282149017 },
		classic => { F => 4.84608786238014, df1 => 2, df2 => 27, p => 0.0159099583256229 },
		aov => { ssb => 3.76634, ssw => 10.49209, msb => 1.88317, msw => 0.388595925925926 },
	},
	# ---- InsectSprays (R built-in data set) ----
	{
		name   => 'InsectSprays',
		cond   => 1.90498,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'A' => [10, 7, 20, 14, 14, 12, 10, 23, 17, 20, 14, 13],
			'B' => [11, 17, 21, 11, 16, 14, 17, 17, 19, 21, 7, 13],
			'C' => [0, 1, 7, 2, 3, 1, 2, 1, 3, 0, 1, 4],
			'D' => [3, 5, 12, 6, 4, 3, 5, 5, 5, 5, 2, 4],
			'E' => [3, 5, 3, 5, 3, 6, 1, 1, 3, 2, 6, 4],
			'F' => [11, 9, 15, 22, 15, 16, 13, 10, 26, 26, 24, 13],
		],
		welch => { F => 36.0654438935773, df1 => 5, df2 => 30.0425605087674, p => 7.99937945567335e-12 },
		classic => { F => 34.7022820554917, df1 => 5, df2 => 66, p => 3.18258372614514e-17 },
		aov => { ssb => 2668.83333333334, ssw => 1015.16666666667, msb => 533.766666666667, msw => 15.3813131313132 },
	},
	# ---- chickwts (R built-in data set) ----
	{
		name   => 'chickwts',
		cond   => 1.47713,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'casein' => [368, 390, 379, 260, 404, 318, 352, 359, 216, 222, 283, 332],
			'horsebean' => [179, 160, 136, 227, 217, 168, 108, 124, 143, 140],
			'linseed' => [309, 229, 181, 141, 260, 203, 148, 169, 213, 257, 244, 271],
			'meatmeal' => [325, 257, 303, 315, 380, 153, 263, 242, 206, 344, 258],
			'soybean' => [243, 230, 248, 327, 329, 250, 193, 271, 316, 267, 199, 171, 158, 248],
			'sunflower' => [423, 340, 392, 339, 341, 226, 320, 295, 334, 322, 297, 318],
		],
		welch => { F => 19.6617243608369, df1 => 5, df2 => 29.9520363861042, p => 1.17705971606649e-08 },
		classic => { F => 15.3647997747125, df1 => 5, df2 => 65, p => 5.93641985347125e-10 },
		aov => { ssb => 231129.16210292, ssw => 195556.020995671, msb => 46225.8324205839, msw => 3008.55416916416 },
	},
	# ---- iris_sepal (R built-in data set) ----
	{
		name   => 'iris_sepal',
		cond   => 1.61946,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'setosa' => [5.1, 4.9, 4.7, 4.6, 5, 5.4, 4.6, 5, 4.4, 4.9, 5.4, 4.8, 4.8, 4.3, 5.8, 5.7, 5.4, 5.1, 5.7,
                   5.1, 5.4, 5.1, 4.6, 5.1, 4.8, 5, 5, 5.2, 5.2, 4.7, 4.8, 5.4, 5.2, 5.5, 4.9, 5, 5.5, 4.9,
                   4.4, 5.1, 5, 4.5, 4.4, 5, 5.1, 4.8, 5.1, 4.6, 5.3, 5],
			'versicolor' => [7, 6.4, 6.9, 5.5, 6.5, 5.7, 6.3, 4.9, 6.6, 5.2, 5, 5.9, 6, 6.1, 5.6, 6.7, 5.6, 5.8, 6.2,
                       5.6, 5.9, 6.1, 6.3, 6.1, 6.4, 6.6, 6.8, 6.7, 6, 5.7, 5.5, 5.5, 5.8, 6, 5.4, 6, 6.7, 6.3,
                       5.6, 5.5, 5.5, 6.1, 5.8, 5, 5.6, 5.7, 5.7, 6.2, 5.1, 5.7],
			'virginica' => [6.3, 5.8, 7.1, 6.3, 6.5, 7.6, 4.9, 7.3, 6.7, 7.2, 6.5, 6.4, 6.8, 5.7, 5.8, 6.4, 6.5, 7.7,
                      7.7, 6, 6.9, 5.6, 7.7, 6.3, 6.7, 7.2, 6.2, 6.1, 6.4, 7.2, 7.4, 7.9, 6.4, 6.3, 6.1, 7.7,
                      6.3, 6.4, 6, 6.9, 6.7, 6.9, 5.8, 6.8, 6.7, 6.7, 6.3, 6.5, 6.2, 5.9],
		],
		welch => { F => 138.908285268938, df1 => 2, df2 => 92.2111453204574, p => 1.5050589627451e-28 },
		classic => { F => 119.264502184505, df1 => 2, df2 => 147, p => 1.66966919076942e-31 },
		aov => { ssb => 63.2121333333333, ssw => 38.9562, msb => 31.6060666666667, msw => 0.265008163265306 },
	},
	# ---- iris_petal (R built-in data set) ----
	{
		name   => 'iris_petal',
		cond   => 3.74984,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'setosa' => [0.2, 0.2, 0.2, 0.2, 0.2, 0.4, 0.3, 0.2, 0.2, 0.1, 0.2, 0.2, 0.1, 0.1, 0.2, 0.4, 0.4, 0.3,
                   0.3, 0.3, 0.2, 0.4, 0.2, 0.5, 0.2, 0.2, 0.4, 0.2, 0.2, 0.2, 0.2, 0.4, 0.1, 0.2, 0.2, 0.2,
                   0.2, 0.1, 0.2, 0.2, 0.3, 0.3, 0.2, 0.6, 0.4, 0.3, 0.2, 0.2, 0.2, 0.2],
			'versicolor' => [1.4, 1.5, 1.5, 1.3, 1.5, 1.3, 1.6, 1, 1.3, 1.4, 1, 1.5, 1, 1.4, 1.3, 1.4, 1.5, 1, 1.5, 1.1,
                       1.8, 1.3, 1.5, 1.2, 1.3, 1.4, 1.4, 1.7, 1.5, 1, 1.1, 1, 1.2, 1.6, 1.5, 1.6, 1.5, 1.3, 1.3,
                       1.3, 1.2, 1.4, 1.2, 1, 1.3, 1.2, 1.3, 1.3, 1.1, 1.3],
			'virginica' => [2.5, 1.9, 2.1, 1.8, 2.2, 2.1, 1.7, 1.8, 1.8, 2.5, 2, 1.9, 2.1, 2, 2.4, 2.3, 1.8, 2.2, 2.3,
                      1.5, 2.3, 2, 2, 1.8, 2.1, 1.8, 1.8, 1.8, 2.1, 1.6, 1.9, 2, 2.2, 1.5, 1.4, 2.3, 2.4, 1.8,
                      1.8, 2.1, 2.4, 2.3, 1.9, 2.3, 2.5, 2.3, 1.9, 2, 2.3, 1.8],
		],
		welch => { F => 1276.88456450503, df1 => 2, df2 => 84.9512538374552, p => 4.13873859523979e-64 },
		classic => { F => 960.007146801806, df1 => 2, df2 => 147, p => 4.16944583944412e-85 },
		aov => { ssb => 80.4133333333333, ssw => 6.1566, msb => 40.2066666666667, msw => 0.0418816326530612 },
	},
	# ---- ToothGrowth (R built-in data set) ----
	{
		name   => 'ToothGrowth',
		cond   => 1.03114,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'OJ' => [15.2, 21.5, 17.6, 9.7, 14.5, 10, 8.2, 9.4, 16.5, 9.7, 19.7, 23.3, 23.6, 26.4, 20, 25.2,
               25.8, 21.2, 14.5, 27.3, 25.5, 26.4, 22.4, 24.5, 24.8, 30.9, 26.4, 27.3, 29.4, 23],
			'VC' => [4.2, 11.5, 7.3, 5.8, 6.4, 10, 11.2, 11.2, 5.2, 7, 16.5, 16.5, 15.2, 17.3, 22.5, 17.3, 13.6,
               14.5, 18.8, 15.5, 23.6, 18.5, 33.9, 25.5, 26.4, 32.5, 26.7, 21.5, 23.3, 29.5],
		],
		welch => { F => 3.66825254107097, df1 => 1, df2 => 55.3094326826406, p => 0.0606345078809341 },
		classic => { F => 3.66825254107097, df1 => 1, df2 => 58, p => 0.0603933712241287 },
		aov => { ssb => 205.35, ssw => 3246.85933333333, msb => 205.35, msw => 55.9803333333333 },
	},
	# ---- ToothGrowth_dose (R built-in data set) ----
	{
		name   => 'ToothGrowth_dose',
		cond   => 1.83452,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'0.5' => [4.2, 11.5, 7.3, 5.8, 6.4, 10, 11.2, 11.2, 5.2, 7, 15.2, 21.5, 17.6, 9.7, 14.5, 10, 8.2,
                9.4, 16.5, 9.7],
			'1' => [16.5, 16.5, 15.2, 17.3, 22.5, 17.3, 13.6, 14.5, 18.8, 15.5, 19.7, 23.3, 23.6, 26.4, 20,
              25.2, 25.8, 21.2, 14.5, 27.3],
			'2' => [23.6, 18.5, 33.9, 25.5, 26.4, 32.5, 26.7, 21.5, 23.3, 29.5, 25.5, 26.4, 22.4, 24.5, 24.8,
              30.9, 26.4, 27.3, 29.4, 23],
		],
		welch => { F => 68.4009767771839, df1 => 2, df2 => 37.7432475430268, p => 2.81238454361498e-13 },
		classic => { F => 67.4157378567425, df1 => 2, df2 => 57, p => 9.53272701169993e-16 },
		aov => { ssb => 2426.43433333334, ssw => 1025.775, msb => 1213.21716666667, msw => 17.996052631579 },
	},
	# ---- mtcars_cyl (R built-in data set) ----
	{
		name   => 'mtcars_cyl',
		cond   => 1.93333,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'4' => [22.8, 24.4, 22.8, 32.4, 30.4, 33.9, 21.5, 27.3, 26, 30.4, 21.4],
			'6' => [21, 21, 21.4, 18.1, 19.2, 17.8, 19.7],
			'8' => [18.7, 14.3, 16.4, 17.3, 15.2, 10.4, 10.4, 14.7, 15.5, 15.2, 13.3, 19.2, 15.8, 15],
		],
		welch => { F => 31.6242364658255, df1 => 2, df2 => 18.0318456017699, p => 1.27080937124479e-06 },
		classic => { F => 39.697515255869, df1 => 2, df2 => 29, p => 4.97891917440021e-09 },
		aov => { ssb => 824.784590097402, ssw => 301.262597402598, msb => 412.392295048701, msw => 10.3883654276758 },
	},
	# ---- mtcars_gear (R built-in data set) ----
	{
		name   => 'mtcars_gear',
		cond   => 1.32355,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'3' => [21.4, 18.7, 18.1, 14.3, 16.4, 17.3, 15.2, 10.4, 10.4, 14.7, 21.5, 15.5, 15.2, 13.3, 19.2],
			'4' => [21, 21, 22.8, 24.4, 22.8, 19.2, 17.8, 32.4, 30.4, 33.9, 27.3, 21.4],
			'5' => [26, 30.4, 15.8, 19.7, 15],
		],
		welch => { F => 11.2848206900225, df1 => 2, df2 => 9.5082767291359, p => 0.00308545200318619 },
		classic => { F => 10.9007196886609, df1 => 2, df2 => 29, p => 0.000294827992857195 },
		aov => { ssb => 483.2431875, ssw => 642.804, msb => 241.62159375, msw => 22.1656551724138 },
	},
	# ---- warpbreaks (R built-in data set) ----
	{
		name   => 'warpbreaks',
		cond   => 1.13252,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'H' => [36, 21, 24, 18, 10, 43, 28, 15, 26, 20, 21, 24, 17, 13, 15, 15, 16, 28],
			'L' => [26, 30, 54, 25, 70, 52, 51, 26, 67, 27, 14, 29, 19, 29, 31, 41, 20, 44],
			'M' => [18, 21, 29, 17, 12, 18, 35, 30, 36, 42, 26, 19, 16, 39, 28, 21, 39, 29],
		],
		welch => { F => 5.80180485480409, df1 => 2, df2 => 32.3199673339782, p => 0.0070316506526074 },
		classic => { F => 7.20611388087116, df1 => 2, df2 => 51, p => 0.00175281674585271 },
		aov => { ssb => 2034.25925925926, ssw => 7198.55555555556, msb => 1017.12962962963, msw => 141.148148148148 },
	},
	# ---- sleep (R built-in data set) ----
	{
		name   => 'sleep',
		cond   => 1.09196,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'1' => [0.7, -1.6, -0.2, -1.2, -0.1, 3.4, 3.7, 0.8, 0, 2],
			'2' => [1.9, 0.8, 1.1, 0.1, -0.1, 4.4, 5.5, 1.6, 4.6, 3.4],
		],
		welch => { F => 3.46262676078045, df1 => 1, df2 => 17.7764735161785, p => 0.0793941401873581 },
		classic => { F => 3.46262676078045, df1 => 1, df2 => 18, p => 0.0791867142159381 },
		aov => { ssb => 12.482, ssw => 64.886, msb => 12.482, msw => 3.60477777777778 },
	},
	# ---- airquality (R built-in data set) ----
	{
		name   => 'airquality',
		cond   => 1.1435,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'5' => [41, 36, 12, 18, 28, 23, 19, 8, 7, 16, 11, 14, 18, 14, 34, 6, 30, 11, 1, 11, 4, 32, 23, 45,
              115, 37],
			'6' => [29, 71, 39, 23, 21, 37, 20, 12, 13],
			'7' => [135, 49, 32, 64, 40, 77, 97, 97, 85, 10, 27, 7, 48, 35, 61, 79, 63, 16, 80, 108, 20, 52,
              82, 50, 64, 59],
			'8' => [39, 9, 16, 78, 35, 66, 122, 89, 110, 44, 28, 65, 22, 59, 23, 31, 44, 21, 9, 45, 168, 73,
              76, 118, 84, 85],
			'9' => [96, 78, 73, 91, 47, 32, 20, 23, 21, 24, 44, 21, 28, 9, 13, 46, 18, 13, 24, 16, 13, 23, 36,
              7, 14, 30, 14, 18, 20],
		],
		welch => { F => 8.0266761837481, df1 => 4, df2 => 42.668201053388, p => 6.43908420252727e-05 },
		classic => { F => 8.53560658861385, df1 => 4, df2 => 111, p => 4.82706453411474e-06 },
		aov => { ssb => 29437.8964780431, ssw => 95705.1638667846, msb => 7359.47411951076, msw => 862.208683484546 },
	},
	# ---- CO2_uptake (R built-in data set) ----
	{
		name   => 'CO2_uptake',
		cond   => 1.05514,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'chilled' => [14.2, 24.1, 30.3, 34.6, 32.5, 35.4, 38.7, 9.3, 27.3, 35, 38.8, 38.6, 37.5, 42.4, 15.1, 21,
                    38.1, 34, 38.9, 39.6, 41.4, 10.5, 14.9, 18.1, 18.9, 19.5, 22.2, 21.9, 7.7, 11.4, 12.3, 13,
                    12.5, 13.7, 14.4, 10.6, 18, 17.9, 17.9, 17.9, 18.9, 19.9],
			'nonchilled' => [16, 30.4, 34.8, 37.2, 35.3, 39.2, 39.7, 13.6, 27.3, 37.1, 41.8, 40.6, 41.4, 44.3, 16.2,
                       32.4, 40.3, 42.1, 42.9, 43.9, 45.5, 10.6, 19.2, 26.2, 30, 30.9, 32.4, 35.5, 12, 22, 30.6,
                       31.8, 32.4, 31.1, 31.5, 11.3, 19.4, 25.8, 27.9, 28.5, 28.1, 27.8],
		],
		welch => { F => 9.29311516955702, df1 => 1, df2 => 80.9446845660787, p => 0.00310693689909926 },
		classic => { F => 9.29311516955702, df1 => 1, df2 => 82, p => 0.00309573325254161 },
		aov => { ssb => 988.114404761905, ssw => 8718.86119047619, msb => 988.114404761905, msw => 106.327575493612 },
	},
	# ---- esoph (R built-in data set) ----
	{
		name   => 'esoph',
		cond   => 1.28681,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'25-34' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
			'35-44' => [0, 1, 0, 0, 0, 3, 1, 0, 0, 0, 0, 0, 2, 0, 2],
			'45-54' => [1, 0, 0, 0, 6, 4, 5, 5, 3, 6, 1, 2, 4, 3, 2, 4],
			'55-64' => [2, 3, 3, 4, 9, 6, 4, 3, 9, 8, 3, 4, 5, 6, 2, 5],
			'65-74' => [5, 4, 2, 0, 17, 3, 5, 6, 4, 2, 1, 3, 1, 1, 1],
			'75+' => [1, 2, 1, 2, 1, 0, 1, 1, 1, 2, 1],
		],
		welch => { F => 24.3787139870212, df1 => 5, df2 => 33.6313196319395, p => 2.68844847474002e-10 },
		classic => { F => 10.7562391809684, df1 => 5, df2 => 82, p => 5.69026549922765e-08 },
		aov => { ssb => 261.201515151516, ssw => 398.25303030303, msb => 52.2403030303031, msw => 4.85674427198817 },
	},
	# ---- OrchardSprays (R built-in data set) ----
	{
		name   => 'OrchardSprays',
		cond   => 1.83922,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'A' => [2, 2, 5, 4, 5, 12, 4, 3],
			'B' => [8, 6, 4, 10, 7, 4, 8, 14],
			'C' => [15, 84, 16, 9, 17, 29, 13, 19],
			'D' => [57, 36, 22, 51, 28, 27, 20, 39],
			'E' => [95, 51, 39, 114, 43, 47, 61, 55],
			'F' => [90, 69, 87, 20, 71, 44, 57, 114],
			'G' => [92, 71, 72, 24, 60, 77, 72, 80],
			'H' => [69, 127, 72, 130, 81, 76, 81, 86],
		],
		welch => { F => 33.5145748760275, df1 => 7, df2 => 22.8427372902999, p => 1.47645669250691e-10 },
		classic => { F => 19.0618168511379, df1 => 7, df2 => 56, p => 9.49886166348619e-13 },
		aov => { ssb => 56159.984375, ssw => 23569.625, msb => 8022.85491071428, msw => 420.886160714286 },
	},
	# ---- faithful (R built-in data set) ----
	{
		name   => 'faithful',
		cond   => 2.36607,   # ||y|| / ||residual||: digits lost to cancellation
		groups => [
			'FALSE' => [1.8, 2.283, 2.883, 1.95, 1.833, 1.75, 2.167, 1.75, 1.6, 1.8, 1.75, 3.067, 1.967, 3.367,
                  2.017, 1.867, 1.833, 1.883, 1.75, 3.833, 2.1, 2, 1.833, 1.733, 1.667, 2.233, 1.75, 1.817,
                  2.067, 1.967, 1.983, 2.017, 4.1, 2.633, 2.167, 2.2, 1.867, 1.833, 1.867, 2.483, 2.1, 1.867,
                  1.783, 2.3, 1.7, 2.317, 1.817, 2.617, 4.067, 1.967, 1.917, 2.267, 1.867, 2.8, 1.833, 1.883,
                  2.033, 2.233, 1.983, 2.017, 1.8, 2.4, 4, 1.8, 2.2, 2, 3.5, 2.367, 1.933, 1.917, 2.083,
                  3.333, 2.417, 1.883, 2.033, 1.833, 2.183, 1.833, 2.25, 2.1, 1.867, 1.783, 1.933, 1.867,
                  3.417, 2.4, 2, 1.867, 1.75, 3.917, 4.083, 2.417, 2.217, 1.883, 1.85, 2.333, 2.35, 2.9,
                  2.083, 2.133, 2.2, 2, 1.85, 1.983, 2.25, 2.15, 1.817],
			'TRUE' => [3.6, 3.333, 4.533, 4.7, 3.6, 4.35, 3.917, 4.2, 4.7, 4.8, 4.25, 3.45, 4.533, 3.6, 4.083,
                 3.85, 4.433, 4.3, 4.467, 4.033, 3.833, 4.833, 4.783, 4.35, 4.567, 4.533, 3.317, 4.633, 4.8,
                 4.716, 4.833, 4.883, 3.717, 4.567, 4.317, 4.5, 4.8, 4.4, 4.167, 4.7, 4.7, 4.033, 4.5, 4,
                 5.067, 4.567, 3.883, 3.6, 4.133, 4.333, 4.067, 4.933, 3.95, 4.517, 4, 4.333, 4.817, 4.3,
                 4.667, 3.75, 4.9, 4.367, 4.5, 4.05, 4.7, 4.85, 3.683, 4.733, 4.9, 4.417, 4.633, 4.6, 4.417,
                 4.25, 4.6, 3.767, 4.5, 4.65, 4.167, 4.333, 4.383, 4.933, 3.733, 4.233, 4.533, 4.817, 4.333,
                 4.633, 5.1, 5.033, 4, 4.6, 3.567, 4.5, 4.083, 3.967, 4.15, 3.833, 4.583, 5, 4.617, 4.583,
                 4.167, 4.333, 4.5, 4, 4.167, 4.583, 4.25, 3.767, 4.433, 4.083, 4.417, 4.8, 4.8, 4.1, 3.966,
                 4.233, 3.5, 4.366, 4.667, 4.35, 4.133, 4.6, 4.367, 3.85, 4.5, 2.383, 4.7, 3.833, 4.233,
                 4.8, 4.15, 4.267, 4.483, 4, 4.117, 4.083, 4.267, 4.55, 4.183, 4.45, 4.283, 3.95, 4.15,
                 4.933, 4.583, 3.833, 4.367, 4.35, 4.45, 3.567, 4.5, 4.15, 3.817, 3.917, 4.45, 4.283, 4.767,
                 4.533, 4.25, 4.75, 4.117, 4.417, 4.467],
		],
		welch => { F => 1078.1426693039, df1 => 1, df2 => 174.669648512916, p => 1.20991045519157e-76 },
		classic => { F => 1241.53263654294, df1 => 1, df2 => 270, p => 5.50783574504488e-103 },
		aov => { ssb => 289.977139379094, ssw => 63.0622388231096, msb => 289.977139379094, msw => 0.233563847492998 },
	},
);

# ---------------------------------------------------------------------------
# Every case, through all three documented input shapes, in both branches.
# ---------------------------------------------------------------------------
for my $c (@CASES) {
	my @names = map { $c->{groups}[2 * $_] } 0 .. (@{ $c->{groups} } / 2 - 1);
	my %hash  = @{ $c->{groups} };
	my @aoa   = map { $hash{$_} } @names;
	my (@y, @lab);
	for my $n (@names) { push @y, @{ $hash{$n} }; push @lab, ($n) x @{ $hash{$n} } }

	for my $branch (qw(welch classic)) {
		my $exp = $c->{$branch} or next;
		my $ve  = $branch eq 'classic' ? 1 : 0;

		my %got = (
			hash    => oneway_test(\%hash, var_equal => $ve),
			aoa     => oneway_test(\@aoa,  var_equal => $ve),
			formula => oneway_test({ y => \@y, lab => \@lab },
			              formula => 'y ~ lab', var_equal => $ve),
		);

		for my $mode (qw(hash aoa formula)) {
			my $r  = $got{$mode};
			my $fk = $mode eq 'formula' ? 'lab' : 'Group';
			my $l  = "$c->{name}/$branch/$mode";
			rel_ok($r->{$fk}{'F value'},  $exp->{F},   "$l: F",
				stat_tol($c->{cond}), $c->{atol});
			rel_ok($r->{$fk}{Df},         $exp->{df1}, "$l: num df");
			rel_ok($r->{Residuals}{Df},   $exp->{df2}, "$l: denom df");
			rel_ok($r->{$fk}{'Pr(>F)'},   $exp->{p},   "$l: p-value",
				tail_tol($c->{cond}, $exp->{df2}));
		}

		# The three shapes must agree. Not bit-for-bit: hash mode visits the
		# groups in Perl's hash order while the other two use the order given,
		# and the sums of squares are accumulated in that order.
		for my $mode (qw(aoa formula)) {
			my $fk = $mode eq 'formula' ? 'lab' : 'Group';
			for my $f ('F value', 'Pr(>F)', 'Sum Sq', 'Mean Sq') {
				rel_ok($got{$mode}{$fk}{$f}, $got{hash}{Group}{$f},
					"$c->{name}/$branch: $mode '$f' matches hash mode",
					stat_tol($c->{cond}), $c->{atol});
			}
			rel_ok($got{$mode}{Residuals}{Df}, $got{hash}{Residuals}{Df},
				"$c->{name}/$branch: $mode residual Df matches hash mode",
				stat_tol($c->{cond}));
		}

		# per-group means and sizes, keyed by name
		for my $n (@names) {
			my @obs  = @{ $hash{$n} };
			my $mean = 0; $mean += $_ for @obs; $mean /= @obs;
			rel_ok($got{hash}{group_stats}{mean}{$n}, $mean,
				"$c->{name}/$branch: mean($n)", 1e-13);
			is($got{hash}{group_stats}{size}{$n}, scalar @obs,
				"$c->{name}/$branch: size($n)");
		}

		# sums of squares vs anova(aov()) -- equal-variance branch only
		if ($branch eq 'classic' && $c->{aov}) {
			my $l = "$c->{name}/aov";
			my $st = stat_tol($c->{cond});
			rel_ok($got{hash}{Group}{'Sum Sq'},      $c->{aov}{ssb}, "$l: Sum Sq (between)",  $st);
			rel_ok($got{hash}{Residuals}{'Sum Sq'},  $c->{aov}{ssw}, "$l: Sum Sq (within)",   $st);
			rel_ok($got{hash}{Group}{'Mean Sq'},     $c->{aov}{msb}, "$l: Mean Sq (between)", $st);
			rel_ok($got{hash}{Residuals}{'Mean Sq'}, $c->{aov}{msw}, "$l: Mean Sq (within)",  $st);
		}
	}
}

# ---------------------------------------------------------------------------
# Tail p-values.  These used to come back as a flat 0 because the p-value was
# built as 1 - pf(F, df1, df2), which has no resolution below the ulp of 1.0.
# References: R pf(F, df1, df2, lower.tail = FALSE) == scipy.stats.f.sf.
# ---------------------------------------------------------------------------
{
	my %hash = @{ (grep { $_->{name} eq 'faithful' } @CASES)[0]{groups} };
	my $w = oneway_test(\%hash);
	my $c = oneway_test(\%hash, var_equal => 1);
	ok($w->{Group}{'Pr(>F)'} > 0, 'Welch p-value of 1.2e-76 does not underflow to 0');
	ok($c->{Group}{'Pr(>F)'} > 0, 'pooled p-value of 5.5e-103 does not underflow to 0');
}

# ---------------------------------------------------------------------------
# Degenerate variances.  R's oneway.test gives NaN throughout the Welch branch
# once a group has zero variance (w_i = n_i/0 = Inf makes its tmp term NaN),
# and F = Inf with p = 0 in the pooled branch when every group is constant.
# ---------------------------------------------------------------------------
{
	my $z = oneway_test({ a => [5, 5, 5, 5], b => [1, 2, 3, 4] });
	ok(is_nan($z->{Group}{'F value'}), 'Welch, one constant group: F is NaN like R');
	ok(is_nan($z->{Residuals}{Df}),
		'Welch, one constant group: denom Df is NaN, not a 1e300 sentinel');
	ok(is_nan($z->{Group}{'Pr(>F)'}), 'Welch, one constant group: p is NaN like R');

	my $i = oneway_test({ a => [5, 5, 5, 5], b => [2, 2, 2, 2], c => [9, 9, 9, 9] },
		var_equal => 1);
	is($i->{Group}{'F value'}, $INF, 'pooled, all groups constant: F is Inf like R');
	is($i->{Group}{'Pr(>F)'},  0,    'pooled, all groups constant: p is 0, not NaN');

	my $s = oneway_test({ a => [3, 3, 3, 3], b => [3, 3, 3, 3] }, var_equal => 1);
	ok(is_nan($s->{Group}{'F value'}), 'pooled, single constant value: F is NaN (0/0)');
	ok(is_nan($s->{Group}{'Pr(>F)'}),  'pooled, single constant value: p is NaN');
}

# ---------------------------------------------------------------------------
# k = 2 must reproduce the corresponding two-sample t test, F == t^2.
# (R: oneway.test(y ~ g) and t.test(a, b) agree by construction.)
# ---------------------------------------------------------------------------
{
	my @a = (2.1, 3.4, 1.9, 2.8, 3.3, 2.2);
	my @b = (4.4, 5.1, 3.9, 4.8, 5.5);
	for my $ve (0, 1) {
		my $lbl = $ve ? 'pooled' : 'Welch';
		my $o = oneway_test({ a => \@a, b => \@b }, var_equal => $ve);
		my $t = t_test(\@a, \@b, var_equal => $ve);
		rel_ok($o->{Group}{'F value'}, $t->{statistic} ** 2, "k=2 $lbl: F == t^2", 1e-13);
		rel_ok($o->{Group}{'Pr(>F)'},  $t->{p_value},        "k=2 $lbl: p == t-test p", 1e-13);
		rel_ok($o->{Residuals}{Df},    $t->{df},             "k=2 $lbl: denom Df == t df", 1e-13);
	}
}

# ---------------------------------------------------------------------------
# Formula mode honours the same data-validation contract as the other two
# shapes: an undef or non-numeric response cell dies instead of being read
# as 0.0.  (It used to be read as 0.0, silently corrupting the statistic.)
# ---------------------------------------------------------------------------
{
	my @lab = qw(a a a b b b);
	throws_ok {
		oneway_test({ y => [1, 2, 3, undef, 5, 6], lab => \@lab }, formula => 'y ~ lab')
	} qr/undefined or non-numeric/, 'formula mode: undef response dies (no silent 0.0)';

	throws_ok {
		oneway_test({ y => [1, 2, 3, 'oops', 5, 6], lab => \@lab }, formula => 'y ~ lab')
	} qr/undefined or non-numeric/, 'formula mode: non-numeric response dies';

	# a clean formula run is unaffected
	# R: oneway.test(1:6 ~ rep(c('a','b'), each = 3)) -> F = 13.5, denom df = 4,
	# p = 0.021311641128756727
	my $ok = oneway_test({ y => [1, 2, 3, 4, 5, 6], lab => \@lab }, formula => 'y ~ lab');
	rel_ok($ok->{lab}{'F value'},  13.5,                  'formula mode: clean run F');
	rel_ok($ok->{Residuals}{Df},   4,                     'formula mode: clean run denom df');
	rel_ok($ok->{lab}{'Pr(>F)'},   0.021311641128756727,  'formula mode: clean run p-value');

	throws_ok {
		oneway_test({ y => [1, 2, 3], lab => [qw(a a)] }, formula => 'y ~ lab')
	} qr/length/, 'formula mode: response/factor length mismatch dies';

	throws_ok {
		oneway_test({ y => [1, 2, 3, 4], lab => [qw(a a a a)] }, formula => 'y ~ lab')
	} qr/2 distinct groups/, 'formula mode: a single factor level dies';

	throws_ok {
		oneway_test({ y => [1, 2, 3], lab => [qw(a a b)] }, formula => 'y ~ lab')
	} qr/need >= 2/, 'formula mode: a factor level with one observation dies';
}

# ---------------------------------------------------------------------------
# Factor identity is the string form of the label, so 0 and '0' are one group
# (this is what makes the R idiom as.factor(ctrl) on a 0/1 column work).
# ---------------------------------------------------------------------------
{
	my $mixed = oneway_test(
		{ y => [1, 2, 3, 9, 8, 7], g => [0, '0', 0, 1, '1', 1] },
		formula => 'y ~ g');
	is(scalar keys %{ $mixed->{group_stats}{size} }, 2,
		'numeric and string labels with the same string form are one group');
	is($mixed->{group_stats}{size}{0}, 3, 'group "0" has 3 observations');
}

done_testing;
