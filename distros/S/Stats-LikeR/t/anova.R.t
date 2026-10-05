#!/usr/bin/env perl
# anova(\%data, formula, ...) against R's anova.lm() and anova.lmlist().
#
# PROVENANCE
#
# %DATA and %EXPECT are frozen output of t/anova.R.R under R 4.6.1 (re-run
# with `Rscript t/anova.R.R`).  The models are R's own:
#
#   lcs_*       src/library/stats/man/anova.lm.Rd: LifeCycleSavings, anova(fit)
#               of sr ~ pop15 + pop75 + dpi + ddpi, the chain fit0 .. fit4, and
#               the "unconventional order" anova(fit4, fit2, fit0), whose
#               five-figure output tests/Examples/stats-Ex.Rout.save pins --
#               @ROUT below is that output, copied verbatim.  lcs_dot is
#               sr ~ . in the sorted column order the module expands '.' in;
#               lcs_negF two models that are not nested, for stat.anova()'s
#               rule that a negative F is NA.
#   wb_fm1      src/library/datasets/man/warpbreaks.Rd: anova(lm(breaks ~
#               wool*tension)).  wb_nested, wb_cells, wb_late_mains and
#               wb_noint refit the same data with the interaction nested in
#               wool, alone, written before its main effects, and with no
#               intercept: the margin rule and R's term order, neither of
#               which anova() followed through 0.3212 (it gave wool:tension
#               2 df where R gives 4 and 5, and attributed tension after the
#               interaction).
#   npk         src/library/datasets/man/npk.Rd: yield ~ block + N*P*K, whose
#               N:P:K is confounded with blocks.
#   tg_*        ToothGrowth with dose numeric: a slope per supplement, and
#               dose - 1 (`- 1` was read as part of a column name).
#   pr8049      tests/reg-tests-2.R:1574 (PR#8049): anova(lm(y ~ 1, offset =
#               1:10), lm(y ~ z, offset = 1:10)), with its set.seed(2) draws,
#               written here as offset(z) in the formula.
#   rank0_*     tests/reg-tests-2.R:942, "examples of 0-rank models": y ~ 0 and
#               y ~ x + 0 with x all zero, y from set.seed(1) (the test itself
#               sets no seed).
#
# Factors are written as strings that do not look like numbers (npk's block
# "b1".."b6", N "N0"/"N1"), since a column of numbers is a covariate here.
# R's tables leave out a term with no estimable columns; this module keeps it
# with Df 0, and %ALIASED lists where that happens.
#
# TOLERANCE
#
# 1e-9 relative on every sum of squares, mean square, F and p-value (absolute
# below 1e-300).  The fit is Givens rotations against R's Householder QR, so
# the two agree to rounding, not bit for bit.  The worst disagreement is
# printed at the end with where it was: 2.0e-14 on a double build (a p-value
# of the unconventional-order table), five orders inside the bound, which is
# the headroom for long-double and quadmath builds.  The @ROUT check
# is to the five significant figures R printed.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR qw(anova);

my %DATA = (
  lcs => {
    'sr' => [11.43, 12.07, 13.17, 5.75, 12.88, 8.79, 0.6, 11.9, 4.98, 10.78, 16.85, 3.59, 11.24, 12.64, 12.55, 10.67, 3.01, 7.7, 1.27, 9, 11.34, 14.28, 21.1, 3.98, 10.35, 15.48, 10.25, 14.65, 10.67, 7.3, 4.44, 2.02, 12.7, 12.78, 12.49, 11.14, 13.3, 11.77, 6.86, 14.13, 5.13, 2.81, 7.81, 7.56, 9.22, 18.56, 7.72, 9.24, 8.89, 4.71],
    'pop15' => [29.35, 23.32, 23.8, 41.89, 42.19, 31.72, 39.74, 44.75, 46.64, 47.64, 24.42, 46.31, 27.84, 25.06, 23.31, 25.62, 46.05, 47.32, 34.03, 41.31, 31.16, 24.52, 27.01, 41.74, 21.8, 32.54, 25.95, 24.71, 32.61, 45.04, 43.56, 41.18, 44.19, 46.26, 28.96, 31.94, 31.92, 27.74, 21.44, 23.49, 43.42, 46.12, 23.27, 29.81, 46.4, 45.25, 41.12, 28.13, 43.69, 47.2],
    'pop75' => [2.87, 4.41, 4.43, 1.67, 0.83, 2.85, 1.34, 0.67, 1.06, 1.14, 3.93, 1.19, 2.37, 4.7, 3.35, 3.1, 0.87, 0.58, 3.08, 0.96, 4.19, 3.48, 1.91, 0.91, 3.73, 2.47, 3.67, 3.25, 3.17, 1.21, 1.2, 1.05, 1.28, 1.12, 2.85, 2.28, 1.52, 2.87, 4.54, 3.73, 1.08, 1.21, 4.46, 3.43, 0.9, 0.56, 1.73, 2.72, 2.07, 0.66],
    'dpi' => [2329.68, 1507.99, 2108.47, 189.13, 728.47, 2982.88, 662.86, 289.52, 276.65, 471.24, 2496.53, 287.77, 1681.25, 2213.82, 2457.12, 870.85, 289.71, 232.44, 1900.1, 88.94, 1139.95, 1390, 1257.28, 207.68, 2449.39, 601.05, 2231.03, 1740.7, 1487.52, 325.54, 568.56, 220.56, 400.06, 152.01, 579.51, 651.11, 250.96, 768.79, 3299.49, 2630.96, 389.66, 249.87, 1813.93, 4001.89, 813.39, 138.33, 380.47, 766.54, 123.58, 242.69],
    'ddpi' => [2.87, 3.93, 3.82, 0.22, 4.56, 2.43, 2.67, 6.51, 3.08, 2.8, 3.99, 2.19, 4.32, 4.52, 3.44, 6.28, 1.48, 3.19, 1.12, 1.54, 2.99, 3.54, 8.21, 5.81, 1.57, 8.12, 3.62, 7.66, 1.76, 2.48, 3.61, 1.03, 0.67, 2, 7.48, 2.19, 2, 4.35, 3.01, 2.7, 2.96, 1.13, 2.01, 2.45, 0.53, 5.14, 10.23, 1.88, 16.71, 5.08],
  },
  wb => {
    'breaks' => [26, 30, 54, 25, 70, 52, 51, 26, 67, 18, 21, 29, 17, 12, 18, 35, 30, 36, 36, 21, 24, 18, 10, 43, 28, 15, 26, 27, 14, 29, 19, 29, 31, 41, 20, 44, 42, 26, 19, 16, 39, 28, 21, 39, 29, 20, 21, 24, 17, 13, 15, 15, 16, 28],
    'wool' => ['A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B'],
    'tension' => ['L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H'],
  },
  npk => {
    'block' => ['b1', 'b1', 'b1', 'b1', 'b2', 'b2', 'b2', 'b2', 'b3', 'b3', 'b3', 'b3', 'b4', 'b4', 'b4', 'b4', 'b5', 'b5', 'b5', 'b5', 'b6', 'b6', 'b6', 'b6'],
    'N' => ['N0', 'N1', 'N0', 'N1', 'N1', 'N1', 'N0', 'N0', 'N0', 'N1', 'N1', 'N0', 'N1', 'N1', 'N0', 'N0', 'N1', 'N0', 'N1', 'N0', 'N1', 'N1', 'N0', 'N0'],
    'P' => ['P1', 'P1', 'P0', 'P0', 'P0', 'P1', 'P0', 'P1', 'P1', 'P1', 'P0', 'P0', 'P0', 'P1', 'P0', 'P1', 'P1', 'P0', 'P0', 'P1', 'P0', 'P1', 'P1', 'P0'],
    'K' => ['K1', 'K0', 'K0', 'K1', 'K0', 'K1', 'K1', 'K0', 'K0', 'K1', 'K0', 'K1', 'K0', 'K1', 'K1', 'K0', 'K0', 'K0', 'K1', 'K1', 'K1', 'K0', 'K1', 'K0'],
    'yield' => [49.5, 62.8, 46.8, 57, 59.8, 58.5, 55.5, 56, 62.8, 55.8, 69.5, 55, 62, 48.8, 45.5, 44.2, 52, 51.5, 49.8, 48.8, 57.2, 59, 53.2, 56],
  },
  tg => {
    'len' => [4.2, 11.5, 7.3, 5.8, 6.4, 10, 11.2, 11.2, 5.2, 7, 16.5, 16.5, 15.2, 17.3, 22.5, 17.3, 13.6, 14.5, 18.8, 15.5, 23.6, 18.5, 33.9, 25.5, 26.4, 32.5, 26.7, 21.5, 23.3, 29.5, 15.2, 21.5, 17.6, 9.7, 14.5, 10, 8.2, 9.4, 16.5, 9.7, 19.7, 23.3, 23.6, 26.4, 20, 25.2, 25.8, 21.2, 14.5, 27.3, 25.5, 26.4, 22.4, 24.5, 24.8, 30.9, 26.4, 27.3, 29.4, 23],
    'supp' => ['VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ'],
    'dose' => [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2],
  },
  pr8049 => {
    'y' => [-0.8969145466249814, 0.1848491846467425, 1.5878453312088232, -1.1303756742462854, -0.08025175655098929, 0.13242028438109446, 0.7079547292717333, -0.2396980241718401, 1.9844739366529267, -0.13878701211966474],
    'z' => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
  },
  rank0 => {
    'y' => [-0.6264538107423324, 0.18364332422208224, -0.8356286124100472, 1.5952808021377916, 0.3295077718153605, -0.8204683841180153, 0.4874290524284853, 0.7383247051292173, 0.5757813516534923, -0.305388387156356],
    'x' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  },
);

my %EXPECT = (
  lcs_fit => { one => {
    'pop15' => [1, 204.1175653746042, 204.1175653746042, 14.11573223175562, 0.0004921954681666071],
    'pop75' => [1, 53.34270967346436, 53.34270967346436, 3.6889103830188352, 0.06112545983034562],
    'dpi' => [1, 12.400946191539543, 12.400946191539543, 0.8575863402001999, 0.359355084778498],
    'ddpi' => [1, 63.05403059275926, 63.05403059275926, 4.360495924722876, 0.04247113872491352],
    'Residuals' => [45, 650.7129981676327, 14.460288848169615, undef, undef],
  } },
  lcs_dot => { one => {
    'ddpi' => [1, 91.37435448773581, 91.37435448773581, 6.31898542602778, 0.015592004746540862],
    'dpi' => [1, 67.53584357620088, 67.53584357620088, 4.670435306328585, 0.03604566742755361],
    'pop15' => [1, 138.7693748514724, 138.7693748514724, 9.596583879376508, 0.0033536263048097436],
    'pop75' => [1, 35.2356789169583, 35.2356789169583, 2.436720267964664, 0.125529794001239],
    'Residuals' => [45, 650.7129981676326, 14.460288848169613, undef, undef],
  } },
  lcs_chain => { cmp => {
    'Res_Df' => [49, 48, 47, 46, 45],
    'RSS' => [983.62825, 779.5106846253956, 726.1679749519313, 713.7670287603918, 650.7129981676327],
    'Df' => [undef, 1, 1, 1, 1],
    'Sum of Sq' => [undef, 204.1175653746044, 53.34270967346424, 12.40094619153956, 63.05403059275909],
    'F' => [undef, 14.115732231755635, 3.688910383018827, 0.8575863402002011, 4.360495924722865],
    'Pr(>F)' => [undef, 0.0004921954681666046, 0.06112545983034587, 0.35935508477849776, 0.04247113872491377],
  } },
  lcs_unconventional => { cmp => {
    'Res_Df' => [45, 47, 49],
    'RSS' => [650.7129981676327, 726.1679749519313, 983.62825],
    'Df' => [undef, -2, -2],
    'Sum of Sq' => [undef, -75.45497678429865, -257.46027504806864],
    'F' => [undef, 2.609041132461533, 8.902321307387231],
    'Pr(>F)' => [undef, 0.0847088477965798, 0.0005526716859402219],
  } },
  lcs_negF => { cmp => {
    'Res_Df' => [48, 47],
    'RSS' => [779.5106846253956, 824.7180519360634],
    'Df' => [undef, 1],
    'Sum of Sq' => [undef, -45.20736731066779],
    'F' => [undef, undef],
    'Pr(>F)' => [undef, undef],
  } },
  wb_fm1 => { one => {
    'wool' => [1, 450.6666666666669, 450.6666666666669, 3.765288361118633, 0.05821297595955979],
    'tension' => [2, 2034.259259259258, 1017.129629629629, 8.498046648358017, 0.0006926209367134451],
    'wool:tension' => [2, 1002.7777777777762, 501.3888888888881, 4.189068966851035, 0.02104419072786319],
    'Residuals' => [48, 5745.111111111113, 119.68981481481485, undef, undef],
  } },
  wb_nested => { one => {
    'wool' => [1, 450.6666666666669, 450.6666666666669, 3.765288361118639, 0.05821297595955957],
    'wool:tension' => [4, 3037.037037037037, 759.2592592592592, 6.343557807604541, 0.00035092270783634974],
    'Residuals' => [48, 5745.111111111104, 119.68981481481467, undef, undef],
  } },
  wb_cells => { one => {
    'wool:tension' => [5, 3487.703703703701, 697.5407407407403, 5.827903918307351, 0.0002771964043476943],
    'Residuals' => [48, 5745.111111111109, 119.68981481481477, undef, undef],
  } },
  wb_late_mains => { one => {
    'wool' => [1, 450.6666666666669, 450.6666666666669, 3.765288361118633, 0.05821297595955979],
    'tension' => [2, 2034.259259259258, 1017.129629629629, 8.498046648358017, 0.0006926209367134451],
    'tension:wool' => [2, 1002.7777777777762, 501.3888888888881, 4.189068966851035, 0.02104419072786319],
    'Residuals' => [48, 5745.111111111113, 119.68981481481485, undef, undef],
  } },
  wb_noint => { one => {
    'wool' => [2, 43235.851851851854, 21617.925925925927, 160.18288298672292, 1.8133397866370875e-22],
    'tension' => [2, 2034.2592592592598, 1017.1296296296299, 7.5366506945931, 0.0013777775226284934],
    'Residuals' => [50, 6747.888888888888, 134.95777777777775, undef, undef],
  } },
  npk => { one => {
    'block' => [5, 343.29500000000013, 68.65900000000002, 4.446666426798111, 0.015938790208193932],
    'N' => [1, 189.2816666666665, 189.2816666666665, 12.258734213650897, 0.004371811825799386],
    'P' => [1, 8.401666666666607, 8.401666666666607, 0.5441298168603561, 0.47490409267443645],
    'K' => [1, 95.20166666666651, 95.20166666666651, 6.165689202317114, 0.02879505350023277],
    'N:P' => [1, 21.281666666666734, 21.281666666666734, 1.378296693412013, 0.26316528287716734],
    'N:K' => [1, 33.13500000000008, 33.13500000000008, 2.145972007339981, 0.16864787850049232],
    'P:K' => [1, 0.4816666666666647, 0.4816666666666647, 0.03119490519195465, 0.8627520856854078],
    'Residuals' => [12, 185.28666666666686, 15.440555555555571, undef, undef],
  } },
  tg_slopes => { one => {
    'supp' => [1, 205.35000000000056, 205.35000000000056, 12.31701990583811, 0.0008936451588724491],
    'supp:dose' => [2, 2313.2244047619065, 1156.6122023809532, 69.37431468254891, 6.982023105102596e-16],
    'Residuals' => [56, 933.634928571429, 16.672052295918373, undef, undef],
  } },
  tg_noint => { one => {
    'dose' => [1, 22726.214880952393, 22726.214880952393, 683.2391568028271, 3.9006516710288804e-34],
    'Residuals' => [59, 1962.485119047619, 33.2624596448749, undef, undef],
  } },
  pr8049 => { cmp => {
    'Res_Df' => [9, 8],
    'RSS' => [75.22133832133488, 7.955032927650803],
    'Df' => [undef, 1],
    'Sum of Sq' => [undef, 67.26630539368408],
    'F' => [undef, 67.64653874391789],
    'Pr(>F)' => [undef, 3.5753151651857835e-05],
  } },
  rank0_empty => { one => {
    'Residuals' => [10, 5.658605687373973, 0.5658605687373973, undef, undef],
  } },
  rank0_zero => { one => {
    'Residuals' => [10, 5.658605687373973, 0.5658605687373973, undef, undef],
  } },
);

# The module's formula for each single-model %EXPECT entry, on which data.
my %ONE = (
	lcs_fit       => [lcs => 'sr ~ pop15 + pop75 + dpi + ddpi'],
	lcs_dot       => [lcs => 'sr ~ .'],
	wb_fm1        => [wb  => 'breaks ~ wool*tension'],
	wb_nested     => [wb  => 'breaks ~ wool + wool:tension'],
	wb_cells      => [wb  => 'breaks ~ wool:tension'],
	wb_late_mains => [wb  => 'breaks ~ tension:wool + wool + tension'],
	wb_noint      => [wb  => 'breaks ~ 0 + wool + tension'],
	npk           => [npk => 'yield ~ block + N*P*K'],
	tg_slopes     => [tg  => 'len ~ supp + supp:dose'],
	tg_noint      => [tg  => 'len ~ dose - 1'],
	rank0_empty   => [rank0 => 'y ~ 0'],
	rank0_zero    => [rank0 => 'y ~ x + 0'],
);
# Terms R leaves out of its table for having no estimable column.
my %ALIASED = (npk => ['N:P:K'], rank0_zero => ['x']);
my %CMP = (
	lcs_chain          => [lcs => 'sr ~ 1', 'sr ~ pop15', 'sr ~ pop15 + pop75',
	                       'sr ~ pop15 + pop75 + dpi', 'sr ~ pop15 + pop75 + dpi + ddpi'],
	lcs_unconventional => [lcs => 'sr ~ pop15 + pop75 + dpi + ddpi', 'sr ~ pop15 + pop75', 'sr ~ 1'],
	lcs_negF           => [lcs => 'sr ~ pop15', 'sr ~ dpi + ddpi'],
	pr8049             => [pr8049 => 'y ~ 1 + offset(z)', 'y ~ z + offset(z)'],
);

my ($worst, $worst_at) = (0, '');
sub near {
	my ($got, $exp, $name) = @_;
	if (!defined $exp) { ok(!defined $got, "$name: absent, as R's NA") or diag("got $got"); return }
	if (!defined $got) { fail("$name: missing"); return }
	my $scale = abs($exp) > 1e-300 ? abs($exp) : 1;
	my $rel = abs($got - $exp) / $scale;
	($worst, $worst_at) = ($rel, $name) if $rel > $worst;
	ok($rel <= 1e-9, $name) or diag("got $got, expected $exp, relative $rel");
}
my @COLS = ('Df', 'Sum Sq', 'Mean Sq', 'F value', 'Pr(>F)');
sub check_one {
	my ($key, $got, $exp) = @_;
	for my $term (sort keys %$exp) {
		ok(exists $got->{$term}, "$key: has term '$term'") or next;
		for my $i (0 .. $#COLS) {
			my $e = $exp->{$term}[$i];
			if ($COLS[$i] eq 'Df') { is($got->{$term}{Df}, $e, "$key $term Df") }
			else { near($got->{$term}{ $COLS[$i] }, $e, "$key $term $COLS[$i]") }
		}
	}
	my %extra = map { $_ => 1 } grep { !exists $exp->{$_} } keys %$got;
	for my $t (@{ $ALIASED{$key} || [] }) {
		ok(delete $extra{$t}, "$key: aliased term '$t' kept") or next;
		is($got->{$t}{Df}, 0, "$key $t: Df 0");
		is($got->{$t}{'Sum Sq'}, 0, "$key $t: Sum Sq 0");
	}
	is_deeply([sort keys %extra], [], "$key: no terms R does not have");
}
sub check_cmp {
	my ($key, $got, $exp) = @_;
	my $nrow = @{ $exp->{'Res_Df'} };
	is(scalar @$got, $nrow, "$key: $nrow rows");
	for my $r (0 .. $nrow - 1) {
		is($got->[$r]{'Res_Df'}, $exp->{'Res_Df'}[$r], "$key row $r Res_Df");
		near($got->[$r]{RSS}, $exp->{RSS}[$r], "$key row $r RSS");
		if (defined $exp->{Df}[$r]) { is($got->[$r]{Df}, $exp->{Df}[$r], "$key row $r Df") }
		else { ok(!exists $got->[$r]{Df}, "$key row $r: no Df") }
		near($got->[$r]{$_}, $exp->{$_}[$r], "$key row $r $_") for 'Sum of Sq', 'F', 'Pr(>F)';
	}
}

for my $key (sort keys %ONE) {
	my ($d, $f) = @{ $ONE{$key} };
	check_one($key, anova($DATA{$d}, $f), $EXPECT{$key}{one});
}
for my $key (sort keys %CMP) {
	my ($d, @f) = @{ $CMP{$key} };
	check_cmp($key, anova($DATA{$d}, @f), $EXPECT{$key}{cmp});
}

# stats-Ex.Rout.save, anova(fit4, fit2, fit0, test = "F"), as printed.
{
	my @ROUT = ([45, 650.71], [47, 726.17, -2, -75.455, 2.6090, 0.0847088],
	            [49, 983.63, -2, -257.460, 8.9023, 0.0005527]);
	my $t = anova($DATA{lcs}, @{ $CMP{lcs_unconventional} }[1 .. 3]);
	my @k = ('Res_Df', 'RSS', 'Df', 'Sum of Sq', 'F', 'Pr(>F)');
	for my $i (0 .. $#ROUT) {
		for my $j (0 .. $#{ $ROUT[$i] }) {
			my $v = $ROUT[$i][$j];
			(my $digits = $v) =~ s/^-?0?\.?0*|\.//g;
			my $tol = 0.5 * 10 ** (int(log(abs $v) / log(10) + ($v =~ /^-?0\./ ? 0 : 1)) - length $digits);
			ok(abs($t->[$i]{ $k[$j] } - $v) <= $tol * 1.000001,
			   "Rout.save row $i $k[$j]: $t->[$i]{$k[$j]} rounds to $v");
		}
	}
}

# Spellings of one model give one table.
{
	my $wb = $DATA{wb};
	my %same = (
		wb_cells  => ['breaks ~ wool:tension + tension:wool', 'breaks ~ tension:wool'],
		wb_noint  => ['breaks ~ wool + tension - 1', 'breaks ~ wool + tension + 0'],
		wb_fm1    => ['breaks ~ wool + tension + wool:tension', 'breaks ~ wool + tension:wool + tension'],
	);
	for my $key (sort keys %same) {
		for my $f (@{ $same{$key} }) {
			my $got = anova($wb, $f);
			my %g = map { ($_ eq 'tension:wool' ? 'wool:tension' : $_) => $got->{$_} } keys %$got;
			is_deeply([sort keys %g], [sort keys %{ $EXPECT{$key}{one} }], "'$f': ${key}'s terms");
			near($g{$_}{'Sum Sq'}, $EXPECT{$key}{one}{$_}[1], "'$f' $_ Sum Sq") for keys %g;
		}
	}
}

# Row order: the fitted model, and so the table, must not depend on it. Up to
# 0.3212 wool:tension alone was coded by contrasts in both factors, a column
# space that moved with which level came first.
{
	my $wb = $DATA{wb};
	my $nr = @{ $wb->{breaks} };
	my %rev = map { my $c = $_; ($c => [ reverse @{ $wb->{$c} } ]) } keys %$wb;
	check_one('wb_cells reversed', anova(\%rev, 'breaks ~ wool:tension'), $EXPECT{wb_cells}{one});
	my @aoh = map { my $i = $_; +{ map { ($_ => $wb->{$_}[$i]) } keys %$wb } } 0 .. $nr - 1;
	check_one('wb_nested AoH', anova(\@aoh, 'breaks ~ wool + wool:tension'), $EXPECT{wb_nested}{one});
	my %hoh = map { my $i = $_; ("r$i" => { map { ($_ => $wb->{$_}[$i]) } keys %$wb }) } 0 .. $nr - 1;
	check_one('wb_nested HoH', anova(\%hoh, 'breaks ~ wool + wool:tension'), $EXPECT{wb_nested}{one});
}

# anova.lmlist(): a model with another response is dropped with a warning, and
# one model left gives that model's own table.
{
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	my $t = anova($DATA{lcs}, 'sr ~ pop15 + pop75 + dpi + ddpi', 'log(sr) ~ pop15');
	is(scalar @w, 1, 'differing response: one warning');
	like($w[0] // '', qr/^anova: models with response 'log\(sr\)' removed because response differs from model 1/,
	     'differing response: R\'s message');
	is(ref $t, 'HASH', 'differing response: one model left gives the single-model table');
	check_one('lcs_fit after drop', $t, $EXPECT{lcs_fit}{one});
	@w = ();
	my $c = anova($DATA{lcs}, 'sr ~ 1', 'log(sr) ~ pop15', 'sr ~ pop15 + pop75', 'sqrt(sr) ~ dpi');
	like($w[0] // '', qr/response 'log\(sr\)', 'sqrt\(sr\)' removed/, 'two dropped models named in one warning');
	is(scalar @$c, 2, 'two models remain');
	is($c->[1]{formula}, 'sr ~ pop15 + pop75', 'the remaining models keep their order');
}

# Argument validation
{
	my $wb = $DATA{wb};
	my %ragged = (y => [1, 2, 3], x => [1, 2]);
	eval { anova(\%ragged, 'y ~ x') };
	like($@, qr/^anova: HoA columns have unequal lengths/, 'ragged columns croak');
	eval { anova($wb, undef) };
	like($@, qr/^anova: second argument must be a formula string/, 'undef formula croaks');
	eval { anova($wb, 'breaks ~ wool', [1]) };
	like($@, qr/^anova: model argument 2 must be a formula string/, 'reference as a later formula croaks');
	eval { anova($wb, 'breaks ~ ') };
	like($@, qr/^anova: could not parse formula/, 'empty right-hand side croaks');
	eval { anova(\'x', 'y ~ x') };
	like($@, qr/^anova: first argument must be a hash or array reference/, 'scalar ref croaks');
}

diag(sprintf 'worst relative disagreement with R: %.3g (%s)', $worst, $worst_at);
done_testing();
