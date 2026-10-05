#!/usr/bin/env perl
#
# Cross-validation of agg() against the two reference implementations, using
# their own test suites and documented examples rather than cases invented here.
# t/agg.t covers the call forms, output shapes, argument validation, the
# regressions fixed in 0.3213 and leak checking; this file does not repeat them.
#
# Provenance of every expected value below:
#
#   * R 4.6.1 (2026-06-24) stats::aggregate.data.frame.  The frozen R table
#     holds the examples in src/library/stats/man/aggregate.Rd (state.x77 by
#     Region and by Region x Cold; testDF by by1 x by2 with NA as a level, both
#     with and without na.rm; weight ~ feed on chickwts, crossed here with
#     every numeric reducer; breaks ~ wool + tension on warpbreaks;
#     cbind(Ozone, Temp) ~ Month on airquality with na.action = na.pass, with
#     and without na.rm; cbind(ncases, ncontrols) ~ alcgp + tobgp on esoph;
#     . ~ Species on iris) and R's own regression cases: tests/reg-tests-1a.R
#     (the one-row result, R-help 2004-05-14; aggregate(1:4, list(groups=f1),
#     sum)), tests/reg-tests-1c.R (PR#15004, 21 grouping columns falsely
#     merged by rounding; PR#15699, no grouping variables) and
#     tests/reg-tests-1d.R (PR#17283, whose own pinned values are also checked
#     below).
#   * pandas 3.0.4 DataFrame.groupby().agg(), the interface agg() follows.  The
#     frozen pandas table holds cases from pandas/tests/groupby/:
#     aggregate/test_aggregate.py (test_groupby_aggregation_mixed_dtype
#     GH#6212, test_groupby_agg_dict_with_getitem GH#25471,
#     test_groupby_agg_dict_dup_columns GH#55006, test_order_aggregate_multiple_funcs
#     GH#25692, test_agg_with_missing_values GH#58810,
#     test_groupby_aggregate_empty_key GH#32580, test_with_na_groups),
#     test_reductions.py (test_basic_aggregations; every float64 row of
#     test_mean_skipna, test_sum_skipna and test_multifunc_skipna for the
#     reducers agg() has, GH#15675, under both skipna settings;
#     test_cython_median; test_nunique) and methods/test_nth.py
#     (test_first_last_with_None_expanded GH#32800/GH#38286).  The error cases
#     at the end come from the same file and are cited where they are used.
#
# The two tables are generated, and the generators are committed next to this
# file: `Rscript t/agg.R.pandas.R` and
# `/home/con/.pyenv/versions/3.14.2/bin/python t/agg.R.pandas.py` print the Perl
# literals to paste back over the BEGIN/END GENERATED blocks below.  The test
# itself never runs R or python and never needs either installed.  What each
# generator normalises -- NA keys kept as groups, pandas' and R's reducer names
# mapped onto agg()'s, R's group order -- is listed in its header; the
# behaviour the references have by default and agg() does not is pinned at the
# end of this file, in the divergence section, rather than hidden.
#
# Every case runs through all four input shapes (HoA as frozen, and AoH, HoH and
# AoA built from it), and each answer is compared group by group.  Where a
# pandas case is marked ordered => 1 the order of the groups is compared too;
# R's order is its own (the first `by` variable varies fastest, factors in level
# order), so R's cases are compared by group only.
#
# Tolerance.  Counts, sums of integers, and min/max/median/first/last are
# compared exactly, as strings, since they are one of the inputs or an exact
# integer.  A mean, sd or var is compared with a relative tolerance of 1e-13.
# The worst disagreement observed (TEST_VERBOSE=1 prints it) was 2.21e-16 on
# perl-5.44.0 (double), and 1.13e-16 on perl-5.12.5 and 5.16.3-thr-ld (long
# double) and on 5.44.0-quadmath, so the bound leaves a factor of about 450.
# On the wider builds the data literals read in as the nearest long double or
# __float128 to the decimal, not as R's or pandas' double, and that, not the
# arithmetic, is most of what those builds' figure measures.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Stats::LikeR 'agg';

my $RTOL = 1e-13;
my $worst = 0;   # largest relative difference seen, reported under TEST_VERBOSE

my @R_CASES = (
# BEGIN GENERATED (R) -- Rscript t/agg.R.pandas.R
	{
		name   => 'aggregate.Rd: state.x77 by Region, mean',
		cols   => [ 'Region', 'Population', 'Income', 'Illiteracy', 'Life Exp', 'Murder', 'HS Grad', 'Frost', 'Area' ],
		data   => {
			'Region' => [ 'South', 'West', 'West', 'South', 'West', 'West', 'Northeast', 'South', 'South', 'South', 'West', 'West', 'North Central', 'North Central', 'North Central', 'North Central', 'South', 'South', 'Northeast', 'South', 'Northeast', 'North Central', 'North Central', 'South', 'North Central', 'West', 'North Central', 'West', 'Northeast', 'Northeast', 'West', 'Northeast', 'South', 'North Central', 'North Central', 'South', 'West', 'Northeast', 'Northeast', 'South', 'North Central', 'South', 'South', 'West', 'Northeast', 'South', 'West', 'South', 'North Central', 'West' ],
			'Population' => [ 3615, 365, 2212, 2110, 21198, 2541, 3100, 579, 8277, 4931, 868, 813, 11197, 5313, 2861, 2280, 3387, 3806, 1058, 4122, 5814, 9111, 3921, 2341, 4767, 746, 1544, 590, 812, 7333, 1144, 18076, 5441, 637, 10735, 2715, 2284, 11860, 931, 2816, 681, 4173, 12237, 1203, 472, 4981, 3559, 1799, 4589, 376 ],
			'Income' => [ 3624, 6315, 4530, 3378, 5114, 4884, 5348, 4809, 4815, 4091, 4963, 4119, 5107, 4458, 4628, 4669, 3712, 3545, 3694, 5299, 4755, 4751, 4675, 3098, 4254, 4347, 4508, 5149, 4281, 5237, 3601, 4903, 3875, 5087, 4561, 3983, 4660, 4449, 4558, 3635, 4167, 3821, 4188, 4022, 3907, 4701, 4864, 3617, 4468, 4566 ],
			'Illiteracy' => [ 2.1, 1.5, 1.8, 1.9, 1.1, 0.7, 1.1, 0.9, 1.3, 2, 1.9, 0.6, 0.9, 0.7, 0.5, 0.6, 1.6, 2.8, 0.7, 0.9, 1.1, 0.9, 0.6, 2.4, 0.8, 0.6, 0.6, 0.5, 0.7, 1.1, 2.2, 1.4, 1.8, 0.8, 0.8, 1.1, 0.6, 1, 1.3, 2.3, 0.5, 1.7, 2.2, 0.6, 0.6, 1.4, 0.6, 1.4, 0.7, 0.6 ],
			'Life Exp' => [ 69.05, 69.31, 70.55, 70.66, 71.71, 72.06, 72.48, 70.06, 70.66, 68.54, 73.6, 71.87, 70.14, 70.88, 72.56, 72.58, 70.1, 68.76, 70.39, 70.22, 71.83, 70.63, 72.96, 68.09, 70.69, 70.56, 72.6, 69.03, 71.23, 70.93, 70.32, 70.55, 69.21, 72.78, 70.82, 71.42, 72.13, 70.43, 71.9, 67.96, 72.08, 70.11, 70.9, 72.9, 71.64, 70.08, 71.72, 69.48, 72.48, 70.29 ],
			'Murder' => [ 15.1, 11.3, 7.8, 10.1, 10.3, 6.8, 3.1, 6.2, 10.7, 13.9, 6.2, 5.3, 10.3, 7.1, 2.3, 4.5, 10.6, 13.2, 2.7, 8.5, 3.3, 11.1, 2.3, 12.5, 9.3, 5, 2.9, 11.5, 3.3, 5.2, 9.7, 10.9, 11.1, 1.4, 7.4, 6.4, 4.2, 6.1, 2.4, 11.6, 1.7, 11, 12.2, 4.5, 5.5, 9.5, 4.3, 6.7, 3, 6.9 ],
			'HS Grad' => [ 41.3, 66.7, 58.1, 39.9, 62.6, 63.9, 56, 54.6, 52.6, 40.6, 61.9, 59.5, 52.6, 52.9, 59, 59.9, 38.5, 42.2, 54.7, 52.3, 58.5, 52.8, 57.6, 41, 48.8, 59.2, 59.3, 65.2, 57.6, 52.5, 55.2, 52.7, 38.5, 50.3, 53.2, 51.6, 60, 50.2, 46.4, 37.8, 53.3, 41.8, 47.4, 67.3, 57.1, 47.8, 63.5, 41.6, 54.5, 62.9 ],
			'Frost' => [ 20, 152, 15, 65, 20, 166, 139, 103, 11, 60, 0, 126, 127, 122, 140, 114, 95, 12, 161, 101, 103, 125, 160, 50, 108, 155, 139, 188, 174, 115, 120, 82, 80, 186, 124, 82, 44, 126, 127, 65, 172, 70, 35, 137, 168, 85, 32, 100, 149, 173 ],
			'Area' => [ 50708, 566432, 113417, 51945, 156361, 103766, 4862, 1982, 54090, 58073, 6425, 82677, 55748, 36097, 55941, 81787, 39650, 44930, 30920, 9891, 7826, 56817, 79289, 47296, 68995, 145587, 76483, 109889, 9027, 7521, 121412, 47831, 48798, 69273, 40975, 68782, 96184, 44966, 1049, 30225, 75955, 41328, 262134, 82096, 9267, 39780, 66570, 24070, 54464, 97203 ],
		},
		by     => [ 'Region' ],
		agg    => { 'Population' => 'mean', 'Income' => 'mean', 'Illiteracy' => 'mean', 'Life Exp' => 'mean', 'Murder' => 'mean', 'HS Grad' => 'mean', 'Frost' => 'mean', 'Area' => 'mean' },
		skipna => 1,
		groups => [
			[ [ 'North Central' ], { 'Population' => 4803, 'Income' => 4611.083333333333, 'Illiteracy' => 0.69999999999999996, 'Life Exp' => 71.766666666666666, 'Murder' => 5.2750000000000004, 'HS Grad' => 54.516666666666666, 'Frost' => 138.83333333333334, 'Area' => 62652 } ],
			[ [ 'Northeast' ], { 'Population' => 5495.1111111111113, 'Income' => 4570.2222222222226, 'Illiteracy' => 1, 'Life Exp' => 71.26444444444445, 'Murder' => 4.7222222222222223, 'HS Grad' => 53.966666666666669, 'Frost' => 132.77777777777777, 'Area' => 18141 } ],
			[ [ 'South' ], { 'Population' => 4208.125, 'Income' => 4011.9375, 'Illiteracy' => 1.7375, 'Life Exp' => 69.706249999999997, 'Murder' => 10.581250000000001, 'HS Grad' => 44.34375, 'Frost' => 64.625, 'Area' => 54605.125 } ],
			[ [ 'West' ], { 'Population' => 2915.3076923076924, 'Income' => 4702.6153846153848, 'Illiteracy' => 1.023076923076923, 'Life Exp' => 71.234615384615381, 'Murder' => 7.2153846153846155, 'HS Grad' => 62, 'Frost' => 102.15384615384616, 'Area' => 134463 } ],
		],
	},
	{
		name   => 'aggregate.Rd / reg-tests-1a.R: state.x77 by Region x Cold, mean',
		cols   => [ 'Region', 'Cold', 'Population', 'Income', 'Illiteracy', 'Life Exp', 'Murder', 'HS Grad', 'Frost', 'Area' ],
		data   => {
			'Region' => [ 'South', 'West', 'West', 'South', 'West', 'West', 'Northeast', 'South', 'South', 'South', 'West', 'West', 'North Central', 'North Central', 'North Central', 'North Central', 'South', 'South', 'Northeast', 'South', 'Northeast', 'North Central', 'North Central', 'South', 'North Central', 'West', 'North Central', 'West', 'Northeast', 'Northeast', 'West', 'Northeast', 'South', 'North Central', 'North Central', 'South', 'West', 'Northeast', 'Northeast', 'South', 'North Central', 'South', 'South', 'West', 'Northeast', 'South', 'West', 'South', 'North Central', 'West' ],
			'Cold' => [ 'FALSE', 'TRUE', 'FALSE', 'FALSE', 'FALSE', 'TRUE', 'TRUE', 'FALSE', 'FALSE', 'FALSE', 'FALSE', 'FALSE', 'FALSE', 'FALSE', 'TRUE', 'FALSE', 'FALSE', 'FALSE', 'TRUE', 'FALSE', 'FALSE', 'FALSE', 'TRUE', 'FALSE', 'FALSE', 'TRUE', 'TRUE', 'TRUE', 'TRUE', 'FALSE', 'FALSE', 'FALSE', 'FALSE', 'TRUE', 'FALSE', 'FALSE', 'FALSE', 'FALSE', 'FALSE', 'FALSE', 'TRUE', 'FALSE', 'FALSE', 'TRUE', 'TRUE', 'FALSE', 'FALSE', 'FALSE', 'TRUE', 'TRUE' ],
			'Population' => [ 3615, 365, 2212, 2110, 21198, 2541, 3100, 579, 8277, 4931, 868, 813, 11197, 5313, 2861, 2280, 3387, 3806, 1058, 4122, 5814, 9111, 3921, 2341, 4767, 746, 1544, 590, 812, 7333, 1144, 18076, 5441, 637, 10735, 2715, 2284, 11860, 931, 2816, 681, 4173, 12237, 1203, 472, 4981, 3559, 1799, 4589, 376 ],
			'Income' => [ 3624, 6315, 4530, 3378, 5114, 4884, 5348, 4809, 4815, 4091, 4963, 4119, 5107, 4458, 4628, 4669, 3712, 3545, 3694, 5299, 4755, 4751, 4675, 3098, 4254, 4347, 4508, 5149, 4281, 5237, 3601, 4903, 3875, 5087, 4561, 3983, 4660, 4449, 4558, 3635, 4167, 3821, 4188, 4022, 3907, 4701, 4864, 3617, 4468, 4566 ],
			'Illiteracy' => [ 2.1, 1.5, 1.8, 1.9, 1.1, 0.7, 1.1, 0.9, 1.3, 2, 1.9, 0.6, 0.9, 0.7, 0.5, 0.6, 1.6, 2.8, 0.7, 0.9, 1.1, 0.9, 0.6, 2.4, 0.8, 0.6, 0.6, 0.5, 0.7, 1.1, 2.2, 1.4, 1.8, 0.8, 0.8, 1.1, 0.6, 1, 1.3, 2.3, 0.5, 1.7, 2.2, 0.6, 0.6, 1.4, 0.6, 1.4, 0.7, 0.6 ],
			'Life Exp' => [ 69.05, 69.31, 70.55, 70.66, 71.71, 72.06, 72.48, 70.06, 70.66, 68.54, 73.6, 71.87, 70.14, 70.88, 72.56, 72.58, 70.1, 68.76, 70.39, 70.22, 71.83, 70.63, 72.96, 68.09, 70.69, 70.56, 72.6, 69.03, 71.23, 70.93, 70.32, 70.55, 69.21, 72.78, 70.82, 71.42, 72.13, 70.43, 71.9, 67.96, 72.08, 70.11, 70.9, 72.9, 71.64, 70.08, 71.72, 69.48, 72.48, 70.29 ],
			'Murder' => [ 15.1, 11.3, 7.8, 10.1, 10.3, 6.8, 3.1, 6.2, 10.7, 13.9, 6.2, 5.3, 10.3, 7.1, 2.3, 4.5, 10.6, 13.2, 2.7, 8.5, 3.3, 11.1, 2.3, 12.5, 9.3, 5, 2.9, 11.5, 3.3, 5.2, 9.7, 10.9, 11.1, 1.4, 7.4, 6.4, 4.2, 6.1, 2.4, 11.6, 1.7, 11, 12.2, 4.5, 5.5, 9.5, 4.3, 6.7, 3, 6.9 ],
			'HS Grad' => [ 41.3, 66.7, 58.1, 39.9, 62.6, 63.9, 56, 54.6, 52.6, 40.6, 61.9, 59.5, 52.6, 52.9, 59, 59.9, 38.5, 42.2, 54.7, 52.3, 58.5, 52.8, 57.6, 41, 48.8, 59.2, 59.3, 65.2, 57.6, 52.5, 55.2, 52.7, 38.5, 50.3, 53.2, 51.6, 60, 50.2, 46.4, 37.8, 53.3, 41.8, 47.4, 67.3, 57.1, 47.8, 63.5, 41.6, 54.5, 62.9 ],
			'Frost' => [ 20, 152, 15, 65, 20, 166, 139, 103, 11, 60, 0, 126, 127, 122, 140, 114, 95, 12, 161, 101, 103, 125, 160, 50, 108, 155, 139, 188, 174, 115, 120, 82, 80, 186, 124, 82, 44, 126, 127, 65, 172, 70, 35, 137, 168, 85, 32, 100, 149, 173 ],
			'Area' => [ 50708, 566432, 113417, 51945, 156361, 103766, 4862, 1982, 54090, 58073, 6425, 82677, 55748, 36097, 55941, 81787, 39650, 44930, 30920, 9891, 7826, 56817, 79289, 47296, 68995, 145587, 76483, 109889, 9027, 7521, 121412, 47831, 48798, 69273, 40975, 68782, 96184, 44966, 1049, 30225, 75955, 41328, 262134, 82096, 9267, 39780, 66570, 24070, 54464, 97203 ],
		},
		by     => [ 'Region', 'Cold' ],
		agg    => { 'Population' => 'mean', 'Income' => 'mean', 'Illiteracy' => 'mean', 'Life Exp' => 'mean', 'Murder' => 'mean', 'HS Grad' => 'mean', 'Frost' => 'mean', 'Area' => 'mean' },
		skipna => 1,
		groups => [
			[ [ 'North Central', 'FALSE' ], { 'Population' => 7233.833333333333, 'Income' => 4633.333333333333, 'Illiteracy' => 0.78333333333333333, 'Life Exp' => 70.956666666666663, 'Murder' => 8.2833333333333332, 'HS Grad' => 53.366666666666667, 'Frost' => 120, 'Area' => 56736.5 } ],
			[ [ 'Northeast', 'FALSE' ], { 'Population' => 8802.7999999999993, 'Income' => 4780.3999999999996, 'Illiteracy' => 1.1799999999999999, 'Life Exp' => 71.128, 'Murder' => 5.5800000000000001, 'HS Grad' => 52.060000000000002, 'Frost' => 110.59999999999999, 'Area' => 21838.599999999999 } ],
			[ [ 'South', 'FALSE' ], { 'Population' => 4208.125, 'Income' => 4011.9375, 'Illiteracy' => 1.7375, 'Life Exp' => 69.706249999999997, 'Murder' => 10.581250000000001, 'HS Grad' => 44.34375, 'Frost' => 64.625, 'Area' => 54605.125 } ],
			[ [ 'West', 'FALSE' ], { 'Population' => 4582.5714285714284, 'Income' => 4550.1428571428569, 'Illiteracy' => 1.2571428571428571, 'Life Exp' => 71.700000000000003, 'Murder' => 6.8285714285714283, 'HS Grad' => 60.114285714285714, 'Frost' => 51, 'Area' => 91863.71428571429 } ],
			[ [ 'North Central', 'TRUE' ], { 'Population' => 2372.1666666666665, 'Income' => 4588.833333333333, 'Illiteracy' => 0.6166666666666667, 'Life Exp' => 72.576666666666668, 'Murder' => 2.2666666666666666, 'HS Grad' => 55.666666666666664, 'Frost' => 157.66666666666666, 'Area' => 68567.5 } ],
			[ [ 'Northeast', 'TRUE' ], { 'Population' => 1360.5, 'Income' => 4307.5, 'Illiteracy' => 0.77500000000000002, 'Life Exp' => 71.435000000000002, 'Murder' => 3.6499999999999999, 'HS Grad' => 56.350000000000001, 'Frost' => 160.5, 'Area' => 13519 } ],
			[ [ 'West', 'TRUE' ], { 'Population' => 970.16666666666663, 'Income' => 4880.5, 'Illiteracy' => 0.75, 'Life Exp' => 70.691666666666663, 'Murder' => 7.666666666666667, 'HS Grad' => 64.200000000000003, 'Frost' => 161.83333333333334, 'Area' => 184162.16666666666 } ],
		],
	},
	{
		name   => 'reg-tests-1d.R PR#17283: Population by Region x Cold',
		cols   => [ 'Region', 'Cold', 'Population' ],
		data   => {
			'Region' => [ 'South', 'West', 'West', 'South', 'West', 'West', 'Northeast', 'South', 'South', 'South', 'West', 'West', 'North Central', 'North Central', 'North Central', 'North Central', 'South', 'South', 'Northeast', 'South', 'Northeast', 'North Central', 'North Central', 'South', 'North Central', 'West', 'North Central', 'West', 'Northeast', 'Northeast', 'West', 'Northeast', 'South', 'North Central', 'North Central', 'South', 'West', 'Northeast', 'Northeast', 'South', 'North Central', 'South', 'South', 'West', 'Northeast', 'South', 'West', 'South', 'North Central', 'West' ],
			'Cold' => [ 'FALSE', 'TRUE', 'FALSE', 'FALSE', 'FALSE', 'TRUE', 'TRUE', 'FALSE', 'FALSE', 'FALSE', 'FALSE', 'FALSE', 'FALSE', 'FALSE', 'TRUE', 'FALSE', 'FALSE', 'FALSE', 'TRUE', 'FALSE', 'FALSE', 'FALSE', 'TRUE', 'FALSE', 'FALSE', 'TRUE', 'TRUE', 'TRUE', 'TRUE', 'FALSE', 'FALSE', 'FALSE', 'FALSE', 'TRUE', 'FALSE', 'FALSE', 'FALSE', 'FALSE', 'FALSE', 'FALSE', 'TRUE', 'FALSE', 'FALSE', 'TRUE', 'TRUE', 'FALSE', 'FALSE', 'FALSE', 'TRUE', 'TRUE' ],
			'Population' => [ 3615, 365, 2212, 2110, 21198, 2541, 3100, 579, 8277, 4931, 868, 813, 11197, 5313, 2861, 2280, 3387, 3806, 1058, 4122, 5814, 9111, 3921, 2341, 4767, 746, 1544, 590, 812, 7333, 1144, 18076, 5441, 637, 10735, 2715, 2284, 11860, 931, 2816, 681, 4173, 12237, 1203, 472, 4981, 3559, 1799, 4589, 376 ],
		},
		by     => [ 'Region', 'Cold' ],
		agg    => { 'Population' => 'mean' },
		skipna => 1,
		groups => [
			[ [ 'North Central', 'FALSE' ], { 'Population' => 7233.833333333333 } ],
			[ [ 'Northeast', 'FALSE' ], { 'Population' => 8802.7999999999993 } ],
			[ [ 'South', 'FALSE' ], { 'Population' => 4208.125 } ],
			[ [ 'West', 'FALSE' ], { 'Population' => 4582.5714285714284 } ],
			[ [ 'North Central', 'TRUE' ], { 'Population' => 2372.1666666666665 } ],
			[ [ 'Northeast', 'TRUE' ], { 'Population' => 1360.5 } ],
			[ [ 'West', 'TRUE' ], { 'Population' => 970.16666666666663 } ],
		],
	},
	{
		name   => 'aggregate.Rd: testDF by by1 x by2, NA as a level, mean (skipna => 0)',
		cols   => [ 'by1', 'by2', 'v1', 'v2' ],
		data   => {
			'by1' => [ 'red', 'blue', '1', '2', undef, 'big', '1', '2', 'red', '1', undef, '12' ],
			'by2' => [ 'wet', 'dry', '99', '95', undef, 'damp', '95', '99', 'red', '99', undef, undef ],
			'v1' => [ 1, 3, 5, 7, 8, 3, 5, undef, 4, 5, 7, 9 ],
			'v2' => [ 11, 33, 55, 77, 88, 33, 55, undef, 44, 55, 77, 99 ],
		},
		by     => [ 'by1', 'by2' ],
		agg    => { 'v1' => 'mean', 'v2' => 'mean' },
		skipna => 0,
		groups => [
			[ [ '1', '95' ], { 'v1' => 5, 'v2' => 55 } ],
			[ [ '2', '95' ], { 'v1' => 7, 'v2' => 77 } ],
			[ [ '1', '99' ], { 'v1' => 5, 'v2' => 55 } ],
			[ [ '2', '99' ], { 'v1' => undef, 'v2' => undef } ],
			[ [ 'big', 'damp' ], { 'v1' => 3, 'v2' => 33 } ],
			[ [ 'blue', 'dry' ], { 'v1' => 3, 'v2' => 33 } ],
			[ [ 'red', 'red' ], { 'v1' => 4, 'v2' => 44 } ],
			[ [ 'red', 'wet' ], { 'v1' => 1, 'v2' => 11 } ],
			[ [ '12', undef ], { 'v1' => 9, 'v2' => 99 } ],
			[ [ undef, undef ], { 'v1' => 7.5, 'v2' => 82.5 } ],
		],
	},
	{
		name   => 'aggregate.Rd: testDF by by1 x by2, NA as a level, mean, na_rm (skipna => 1)',
		cols   => [ 'by1', 'by2', 'v1', 'v2' ],
		data   => {
			'by1' => [ 'red', 'blue', '1', '2', undef, 'big', '1', '2', 'red', '1', undef, '12' ],
			'by2' => [ 'wet', 'dry', '99', '95', undef, 'damp', '95', '99', 'red', '99', undef, undef ],
			'v1' => [ 1, 3, 5, 7, 8, 3, 5, undef, 4, 5, 7, 9 ],
			'v2' => [ 11, 33, 55, 77, 88, 33, 55, undef, 44, 55, 77, 99 ],
		},
		by     => [ 'by1', 'by2' ],
		agg    => { 'v1' => 'mean', 'v2' => 'mean' },
		skipna => 1,
		groups => [
			[ [ '1', '95' ], { 'v1' => 5, 'v2' => 55 } ],
			[ [ '2', '95' ], { 'v1' => 7, 'v2' => 77 } ],
			[ [ '1', '99' ], { 'v1' => 5, 'v2' => 55 } ],
			[ [ '2', '99' ], { 'v1' => undef, 'v2' => undef } ],
			[ [ 'big', 'damp' ], { 'v1' => 3, 'v2' => 33 } ],
			[ [ 'blue', 'dry' ], { 'v1' => 3, 'v2' => 33 } ],
			[ [ 'red', 'red' ], { 'v1' => 4, 'v2' => 44 } ],
			[ [ 'red', 'wet' ], { 'v1' => 1, 'v2' => 11 } ],
			[ [ '12', undef ], { 'v1' => 9, 'v2' => 99 } ],
			[ [ undef, undef ], { 'v1' => 7.5, 'v2' => 82.5 } ],
		],
	},
	{
		name   => 'aggregate.Rd: weight ~ feed (chickwts), every reducer',
		cols   => [ 'feed', 'weight' ],
		data   => {
			'feed' => [ 'horsebean', 'horsebean', 'horsebean', 'horsebean', 'horsebean', 'horsebean', 'horsebean', 'horsebean', 'horsebean', 'horsebean', 'linseed', 'linseed', 'linseed', 'linseed', 'linseed', 'linseed', 'linseed', 'linseed', 'linseed', 'linseed', 'linseed', 'linseed', 'soybean', 'soybean', 'soybean', 'soybean', 'soybean', 'soybean', 'soybean', 'soybean', 'soybean', 'soybean', 'soybean', 'soybean', 'soybean', 'soybean', 'sunflower', 'sunflower', 'sunflower', 'sunflower', 'sunflower', 'sunflower', 'sunflower', 'sunflower', 'sunflower', 'sunflower', 'sunflower', 'sunflower', 'meatmeal', 'meatmeal', 'meatmeal', 'meatmeal', 'meatmeal', 'meatmeal', 'meatmeal', 'meatmeal', 'meatmeal', 'meatmeal', 'meatmeal', 'casein', 'casein', 'casein', 'casein', 'casein', 'casein', 'casein', 'casein', 'casein', 'casein', 'casein', 'casein' ],
			'weight' => [ 179, 160, 136, 227, 217, 168, 108, 124, 143, 140, 309, 229, 181, 141, 260, 203, 148, 169, 213, 257, 244, 271, 243, 230, 248, 327, 329, 250, 193, 271, 316, 267, 199, 171, 158, 248, 423, 340, 392, 339, 341, 226, 320, 295, 334, 322, 297, 318, 325, 257, 303, 315, 380, 153, 263, 242, 206, 344, 258, 368, 390, 379, 260, 404, 318, 352, 359, 216, 222, 283, 332 ],
		},
		by     => [ 'feed' ],
		agg    => { 'weight' => [ 'mean', 'median', 'sum', 'sd', 'var', 'min', 'max', 'n', 'count' ] },
		skipna => 1,
		groups => [
			[ [ 'casein' ], { 'weight_mean' => 323.58333333333331, 'weight_median' => 342, 'weight_sum' => 3883, 'weight_sd' => 64.433839688239104, 'weight_var' => 4151.719696969697, 'weight_min' => 216, 'weight_max' => 404, 'weight_n' => 12, 'weight_count' => 12 } ],
			[ [ 'horsebean' ], { 'weight_mean' => 160.19999999999999, 'weight_median' => 151.5, 'weight_sum' => 1602, 'weight_sd' => 38.625840515845809, 'weight_var' => 1491.9555555555555, 'weight_min' => 108, 'weight_max' => 227, 'weight_n' => 10, 'weight_count' => 10 } ],
			[ [ 'linseed' ], { 'weight_mean' => 218.75, 'weight_median' => 221, 'weight_sum' => 2625, 'weight_sd' => 52.235698347185732, 'weight_var' => 2728.568181818182, 'weight_min' => 141, 'weight_max' => 309, 'weight_n' => 12, 'weight_count' => 12 } ],
			[ [ 'meatmeal' ], { 'weight_mean' => 276.90909090909093, 'weight_median' => 263, 'weight_sum' => 3046, 'weight_sd' => 64.900623333608351, 'weight_var' => 4212.090909090909, 'weight_min' => 153, 'weight_max' => 380, 'weight_n' => 11, 'weight_count' => 11 } ],
			[ [ 'soybean' ], { 'weight_mean' => 246.42857142857142, 'weight_median' => 248, 'weight_sum' => 3450, 'weight_sd' => 54.129068382487837, 'weight_var' => 2929.9560439560441, 'weight_min' => 158, 'weight_max' => 329, 'weight_n' => 14, 'weight_count' => 14 } ],
			[ [ 'sunflower' ], { 'weight_mean' => 328.91666666666669, 'weight_median' => 328, 'weight_sum' => 3947, 'weight_sd' => 48.836384225722774, 'weight_var' => 2384.992424242424, 'weight_min' => 226, 'weight_max' => 423, 'weight_n' => 12, 'weight_count' => 12 } ],
		],
	},
	{
		name   => 'aggregate.Rd: breaks ~ wool + tension (warpbreaks), mean and sd',
		cols   => [ 'wool', 'tension', 'breaks' ],
		data   => {
			'wool' => [ 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B' ],
			'tension' => [ 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H' ],
			'breaks' => [ 26, 30, 54, 25, 70, 52, 51, 26, 67, 18, 21, 29, 17, 12, 18, 35, 30, 36, 36, 21, 24, 18, 10, 43, 28, 15, 26, 27, 14, 29, 19, 29, 31, 41, 20, 44, 42, 26, 19, 16, 39, 28, 21, 39, 29, 20, 21, 24, 17, 13, 15, 15, 16, 28 ],
		},
		by     => [ 'wool', 'tension' ],
		agg    => { 'breaks' => [ 'mean', 'sd' ] },
		skipna => 1,
		groups => [
			[ [ 'A', 'H' ], { 'breaks_mean' => 24.555555555555557, 'breaks_sd' => 10.27267140415665 } ],
			[ [ 'B', 'H' ], { 'breaks_mean' => 18.777777777777779, 'breaks_sd' => 4.8933060853010657 } ],
			[ [ 'A', 'L' ], { 'breaks_mean' => 44.555555555555557, 'breaks_sd' => 18.097728525364108 } ],
			[ [ 'B', 'L' ], { 'breaks_mean' => 28.222222222222221, 'breaks_sd' => 9.8587242807801676 } ],
			[ [ 'A', 'M' ], { 'breaks_mean' => 24, 'breaks_sd' => 8.6602540378443873 } ],
			[ [ 'B', 'M' ], { 'breaks_mean' => 28.777777777777779, 'breaks_sd' => 9.4310362338634057 } ],
		],
	},
	{
		name   => 'aggregate.Rd: cbind(Ozone, Temp) ~ Month (airquality), na.action = na.pass, na.rm = TRUE (skipna => 1)',
		cols   => [ 'Month', 'Ozone', 'Temp' ],
		data   => {
			'Month' => [ 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9 ],
			'Ozone' => [ 41, 36, 12, 18, undef, 28, 23, 19, 8, undef, 7, 16, 11, 14, 18, 14, 34, 6, 30, 11, 1, 11, 4, 32, undef, undef, undef, 23, 45, 115, 37, undef, undef, undef, undef, undef, undef, 29, undef, 71, 39, undef, undef, 23, undef, undef, 21, 37, 20, 12, 13, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, 135, 49, 32, undef, 64, 40, 77, 97, 97, 85, undef, 10, 27, undef, 7, 48, 35, 61, 79, 63, 16, undef, undef, 80, 108, 20, 52, 82, 50, 64, 59, 39, 9, 16, 78, 35, 66, 122, 89, 110, undef, undef, 44, 28, 65, undef, 22, 59, 23, 31, 44, 21, 9, undef, 45, 168, 73, undef, 76, 118, 84, 85, 96, 78, 73, 91, 47, 32, 20, 23, 21, 24, 44, 21, 28, 9, 13, 46, 18, 13, 24, 16, 13, 23, 36, 7, 14, 30, undef, 14, 18, 20 ],
			'Temp' => [ 67, 72, 74, 62, 56, 66, 65, 59, 61, 69, 74, 69, 66, 68, 58, 64, 66, 57, 68, 62, 59, 73, 61, 61, 57, 58, 57, 67, 81, 79, 76, 78, 74, 67, 84, 85, 79, 82, 87, 90, 87, 93, 92, 82, 80, 79, 77, 72, 65, 73, 76, 77, 76, 76, 76, 75, 78, 73, 80, 77, 83, 84, 85, 81, 84, 83, 83, 88, 92, 92, 89, 82, 73, 81, 91, 80, 81, 82, 84, 87, 85, 74, 81, 82, 86, 85, 82, 86, 88, 86, 83, 81, 81, 81, 82, 86, 85, 87, 89, 90, 90, 92, 86, 86, 82, 80, 79, 77, 79, 76, 78, 78, 77, 72, 75, 79, 81, 86, 88, 97, 94, 96, 94, 91, 92, 93, 93, 87, 84, 80, 78, 75, 73, 81, 76, 77, 71, 71, 78, 67, 76, 68, 82, 64, 71, 81, 69, 63, 70, 77, 75, 76, 68 ],
		},
		by     => [ 'Month' ],
		agg    => { 'Ozone' => [ 'mean', 'median', 'count', 'n' ], 'Temp' => [ 'mean', 'median', 'count', 'n' ] },
		skipna => 1,
		groups => [
			[ [ 5 ], { 'Ozone_mean' => 23.615384615384617, 'Ozone_median' => 18, 'Ozone_count' => 26, 'Ozone_n' => 31, 'Temp_mean' => 65.548387096774192, 'Temp_median' => 66, 'Temp_count' => 31, 'Temp_n' => 31 } ],
			[ [ 6 ], { 'Ozone_mean' => 29.444444444444443, 'Ozone_median' => 23, 'Ozone_count' => 9, 'Ozone_n' => 30, 'Temp_mean' => 79.099999999999994, 'Temp_median' => 78, 'Temp_count' => 30, 'Temp_n' => 30 } ],
			[ [ 7 ], { 'Ozone_mean' => 59.115384615384613, 'Ozone_median' => 60, 'Ozone_count' => 26, 'Ozone_n' => 31, 'Temp_mean' => 83.903225806451616, 'Temp_median' => 84, 'Temp_count' => 31, 'Temp_n' => 31 } ],
			[ [ 8 ], { 'Ozone_mean' => 59.96153846153846, 'Ozone_median' => 52, 'Ozone_count' => 26, 'Ozone_n' => 31, 'Temp_mean' => 83.967741935483872, 'Temp_median' => 82, 'Temp_count' => 31, 'Temp_n' => 31 } ],
			[ [ 9 ], { 'Ozone_mean' => 31.448275862068964, 'Ozone_median' => 23, 'Ozone_count' => 29, 'Ozone_n' => 30, 'Temp_mean' => 76.900000000000006, 'Temp_median' => 76, 'Temp_count' => 30, 'Temp_n' => 30 } ],
		],
	},
	{
		name   => 'aggregate.Rd: cbind(Ozone, Temp) ~ Month (airquality), na.action = na.pass, no na_rm (skipna => 0)',
		cols   => [ 'Month', 'Ozone', 'Temp' ],
		data   => {
			'Month' => [ 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9 ],
			'Ozone' => [ 41, 36, 12, 18, undef, 28, 23, 19, 8, undef, 7, 16, 11, 14, 18, 14, 34, 6, 30, 11, 1, 11, 4, 32, undef, undef, undef, 23, 45, 115, 37, undef, undef, undef, undef, undef, undef, 29, undef, 71, 39, undef, undef, 23, undef, undef, 21, 37, 20, 12, 13, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, 135, 49, 32, undef, 64, 40, 77, 97, 97, 85, undef, 10, 27, undef, 7, 48, 35, 61, 79, 63, 16, undef, undef, 80, 108, 20, 52, 82, 50, 64, 59, 39, 9, 16, 78, 35, 66, 122, 89, 110, undef, undef, 44, 28, 65, undef, 22, 59, 23, 31, 44, 21, 9, undef, 45, 168, 73, undef, 76, 118, 84, 85, 96, 78, 73, 91, 47, 32, 20, 23, 21, 24, 44, 21, 28, 9, 13, 46, 18, 13, 24, 16, 13, 23, 36, 7, 14, 30, undef, 14, 18, 20 ],
			'Temp' => [ 67, 72, 74, 62, 56, 66, 65, 59, 61, 69, 74, 69, 66, 68, 58, 64, 66, 57, 68, 62, 59, 73, 61, 61, 57, 58, 57, 67, 81, 79, 76, 78, 74, 67, 84, 85, 79, 82, 87, 90, 87, 93, 92, 82, 80, 79, 77, 72, 65, 73, 76, 77, 76, 76, 76, 75, 78, 73, 80, 77, 83, 84, 85, 81, 84, 83, 83, 88, 92, 92, 89, 82, 73, 81, 91, 80, 81, 82, 84, 87, 85, 74, 81, 82, 86, 85, 82, 86, 88, 86, 83, 81, 81, 81, 82, 86, 85, 87, 89, 90, 90, 92, 86, 86, 82, 80, 79, 77, 79, 76, 78, 78, 77, 72, 75, 79, 81, 86, 88, 97, 94, 96, 94, 91, 92, 93, 93, 87, 84, 80, 78, 75, 73, 81, 76, 77, 71, 71, 78, 67, 76, 68, 82, 64, 71, 81, 69, 63, 70, 77, 75, 76, 68 ],
		},
		by     => [ 'Month' ],
		agg    => { 'Ozone' => 'mean', 'Temp' => 'mean' },
		skipna => 0,
		groups => [
			[ [ 5 ], { 'Ozone' => undef, 'Temp' => 65.548387096774192 } ],
			[ [ 6 ], { 'Ozone' => undef, 'Temp' => 79.099999999999994 } ],
			[ [ 7 ], { 'Ozone' => undef, 'Temp' => 83.903225806451616 } ],
			[ [ 8 ], { 'Ozone' => undef, 'Temp' => 83.967741935483872 } ],
			[ [ 9 ], { 'Ozone' => undef, 'Temp' => 76.900000000000006 } ],
		],
	},
	{
		name   => 'aggregate.Rd: cbind(ncases, ncontrols) ~ alcgp + tobgp (esoph), sum',
		cols   => [ 'alcgp', 'tobgp', 'ncases', 'ncontrols' ],
		data   => {
			'alcgp' => [ '0-39g/day', '0-39g/day', '0-39g/day', '0-39g/day', '40-79', '40-79', '40-79', '40-79', '80-119', '80-119', '80-119', '120+', '120+', '120+', '120+', '0-39g/day', '0-39g/day', '0-39g/day', '0-39g/day', '40-79', '40-79', '40-79', '40-79', '80-119', '80-119', '80-119', '80-119', '120+', '120+', '120+', '0-39g/day', '0-39g/day', '0-39g/day', '0-39g/day', '40-79', '40-79', '40-79', '40-79', '80-119', '80-119', '80-119', '80-119', '120+', '120+', '120+', '120+', '0-39g/day', '0-39g/day', '0-39g/day', '0-39g/day', '40-79', '40-79', '40-79', '40-79', '80-119', '80-119', '80-119', '80-119', '120+', '120+', '120+', '120+', '0-39g/day', '0-39g/day', '0-39g/day', '0-39g/day', '40-79', '40-79', '40-79', '80-119', '80-119', '80-119', '80-119', '120+', '120+', '120+', '120+', '0-39g/day', '0-39g/day', '0-39g/day', '40-79', '40-79', '40-79', '40-79', '80-119', '80-119', '120+', '120+' ],
			'tobgp' => [ '0-9g/day', '10-19', '20-29', '30+', '0-9g/day', '10-19', '20-29', '30+', '0-9g/day', '10-19', '30+', '0-9g/day', '10-19', '20-29', '30+', '0-9g/day', '10-19', '20-29', '30+', '0-9g/day', '10-19', '20-29', '30+', '0-9g/day', '10-19', '20-29', '30+', '0-9g/day', '10-19', '20-29', '0-9g/day', '10-19', '20-29', '30+', '0-9g/day', '10-19', '20-29', '30+', '0-9g/day', '10-19', '20-29', '30+', '0-9g/day', '10-19', '20-29', '30+', '0-9g/day', '10-19', '20-29', '30+', '0-9g/day', '10-19', '20-29', '30+', '0-9g/day', '10-19', '20-29', '30+', '0-9g/day', '10-19', '20-29', '30+', '0-9g/day', '10-19', '20-29', '30+', '0-9g/day', '10-19', '20-29', '0-9g/day', '10-19', '20-29', '30+', '0-9g/day', '10-19', '20-29', '30+', '0-9g/day', '10-19', '30+', '0-9g/day', '10-19', '20-29', '30+', '0-9g/day', '10-19', '0-9g/day', '10-19' ],
			'ncases' => [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 3, 1, 0, 0, 0, 0, 0, 2, 0, 2, 1, 0, 0, 0, 6, 4, 5, 5, 3, 6, 1, 2, 4, 3, 2, 4, 2, 3, 3, 4, 9, 6, 4, 3, 9, 8, 3, 4, 5, 6, 2, 5, 5, 4, 2, 0, 17, 3, 5, 6, 4, 2, 1, 3, 1, 1, 1, 1, 2, 1, 2, 1, 0, 1, 1, 1, 2, 1 ],
			'ncontrols' => [ 40, 10, 6, 5, 27, 7, 4, 7, 2, 1, 2, 1, 0, 1, 2, 60, 13, 7, 8, 35, 20, 13, 8, 11, 6, 2, 1, 1, 3, 2, 45, 18, 10, 4, 32, 17, 10, 2, 13, 8, 4, 2, 0, 1, 1, 0, 47, 19, 9, 2, 31, 15, 13, 3, 9, 7, 3, 0, 5, 1, 1, 1, 43, 10, 5, 2, 17, 7, 4, 7, 8, 1, 0, 1, 1, 0, 0, 17, 4, 2, 3, 2, 3, 0, 0, 0, 0, 0 ],
		},
		by     => [ 'alcgp', 'tobgp' ],
		agg    => { 'ncases' => 'sum', 'ncontrols' => 'sum' },
		skipna => 1,
		groups => [
			[ [ '0-39g/day', '0-9g/day' ], { 'ncases' => 9, 'ncontrols' => 252 } ],
			[ [ '120+', '0-9g/day' ], { 'ncases' => 16, 'ncontrols' => 8 } ],
			[ [ '40-79', '0-9g/day' ], { 'ncases' => 34, 'ncontrols' => 145 } ],
			[ [ '80-119', '0-9g/day' ], { 'ncases' => 19, 'ncontrols' => 42 } ],
			[ [ '0-39g/day', '10-19' ], { 'ncases' => 10, 'ncontrols' => 74 } ],
			[ [ '120+', '10-19' ], { 'ncases' => 12, 'ncontrols' => 6 } ],
			[ [ '40-79', '10-19' ], { 'ncases' => 17, 'ncontrols' => 68 } ],
			[ [ '80-119', '10-19' ], { 'ncases' => 19, 'ncontrols' => 30 } ],
			[ [ '0-39g/day', '20-29' ], { 'ncases' => 5, 'ncontrols' => 37 } ],
			[ [ '120+', '20-29' ], { 'ncases' => 7, 'ncontrols' => 5 } ],
			[ [ '40-79', '20-29' ], { 'ncases' => 15, 'ncontrols' => 47 } ],
			[ [ '80-119', '20-29' ], { 'ncases' => 6, 'ncontrols' => 10 } ],
			[ [ '0-39g/day', '30+' ], { 'ncases' => 5, 'ncontrols' => 23 } ],
			[ [ '120+', '30+' ], { 'ncases' => 10, 'ncontrols' => 3 } ],
			[ [ '40-79', '30+' ], { 'ncases' => 9, 'ncontrols' => 20 } ],
			[ [ '80-119', '30+' ], { 'ncases' => 7, 'ncontrols' => 5 } ],
		],
	},
	{
		name   => 'aggregate.Rd: . ~ Species (iris), mean',
		cols   => [ 'Species', 'Sepal.Length', 'Sepal.Width', 'Petal.Length', 'Petal.Width' ],
		data   => {
			'Species' => [ 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica' ],
			'Sepal.Length' => [ 5.1, 4.9, 4.7, 4.6, 5, 5.4, 4.6, 5, 4.4, 4.9, 5.4, 4.8, 4.8, 4.3, 5.8, 5.7, 5.4, 5.1, 5.7, 5.1, 5.4, 5.1, 4.6, 5.1, 4.8, 5, 5, 5.2, 5.2, 4.7, 4.8, 5.4, 5.2, 5.5, 4.9, 5, 5.5, 4.9, 4.4, 5.1, 5, 4.5, 4.4, 5, 5.1, 4.8, 5.1, 4.6, 5.3, 5, 7, 6.4, 6.9, 5.5, 6.5, 5.7, 6.3, 4.9, 6.6, 5.2, 5, 5.9, 6, 6.1, 5.6, 6.7, 5.6, 5.8, 6.2, 5.6, 5.9, 6.1, 6.3, 6.1, 6.4, 6.6, 6.8, 6.7, 6, 5.7, 5.5, 5.5, 5.8, 6, 5.4, 6, 6.7, 6.3, 5.6, 5.5, 5.5, 6.1, 5.8, 5, 5.6, 5.7, 5.7, 6.2, 5.1, 5.7, 6.3, 5.8, 7.1, 6.3, 6.5, 7.6, 4.9, 7.3, 6.7, 7.2, 6.5, 6.4, 6.8, 5.7, 5.8, 6.4, 6.5, 7.7, 7.7, 6, 6.9, 5.6, 7.7, 6.3, 6.7, 7.2, 6.2, 6.1, 6.4, 7.2, 7.4, 7.9, 6.4, 6.3, 6.1, 7.7, 6.3, 6.4, 6, 6.9, 6.7, 6.9, 5.8, 6.8, 6.7, 6.7, 6.3, 6.5, 6.2, 5.9 ],
			'Sepal.Width' => [ 3.5, 3, 3.2, 3.1, 3.6, 3.9, 3.4, 3.4, 2.9, 3.1, 3.7, 3.4, 3, 3, 4, 4.4, 3.9, 3.5, 3.8, 3.8, 3.4, 3.7, 3.6, 3.3, 3.4, 3, 3.4, 3.5, 3.4, 3.2, 3.1, 3.4, 4.1, 4.2, 3.1, 3.2, 3.5, 3.6, 3, 3.4, 3.5, 2.3, 3.2, 3.5, 3.8, 3, 3.8, 3.2, 3.7, 3.3, 3.2, 3.2, 3.1, 2.3, 2.8, 2.8, 3.3, 2.4, 2.9, 2.7, 2, 3, 2.2, 2.9, 2.9, 3.1, 3, 2.7, 2.2, 2.5, 3.2, 2.8, 2.5, 2.8, 2.9, 3, 2.8, 3, 2.9, 2.6, 2.4, 2.4, 2.7, 2.7, 3, 3.4, 3.1, 2.3, 3, 2.5, 2.6, 3, 2.6, 2.3, 2.7, 3, 2.9, 2.9, 2.5, 2.8, 3.3, 2.7, 3, 2.9, 3, 3, 2.5, 2.9, 2.5, 3.6, 3.2, 2.7, 3, 2.5, 2.8, 3.2, 3, 3.8, 2.6, 2.2, 3.2, 2.8, 2.8, 2.7, 3.3, 3.2, 2.8, 3, 2.8, 3, 2.8, 3.8, 2.8, 2.8, 2.6, 3, 3.4, 3.1, 3, 3.1, 3.1, 3.1, 2.7, 3.2, 3.3, 3, 2.5, 3, 3.4, 3 ],
			'Petal.Length' => [ 1.4, 1.4, 1.3, 1.5, 1.4, 1.7, 1.4, 1.5, 1.4, 1.5, 1.5, 1.6, 1.4, 1.1, 1.2, 1.5, 1.3, 1.4, 1.7, 1.5, 1.7, 1.5, 1, 1.7, 1.9, 1.6, 1.6, 1.5, 1.4, 1.6, 1.6, 1.5, 1.5, 1.4, 1.5, 1.2, 1.3, 1.4, 1.3, 1.5, 1.3, 1.3, 1.3, 1.6, 1.9, 1.4, 1.6, 1.4, 1.5, 1.4, 4.7, 4.5, 4.9, 4, 4.6, 4.5, 4.7, 3.3, 4.6, 3.9, 3.5, 4.2, 4, 4.7, 3.6, 4.4, 4.5, 4.1, 4.5, 3.9, 4.8, 4, 4.9, 4.7, 4.3, 4.4, 4.8, 5, 4.5, 3.5, 3.8, 3.7, 3.9, 5.1, 4.5, 4.5, 4.7, 4.4, 4.1, 4, 4.4, 4.6, 4, 3.3, 4.2, 4.2, 4.2, 4.3, 3, 4.1, 6, 5.1, 5.9, 5.6, 5.8, 6.6, 4.5, 6.3, 5.8, 6.1, 5.1, 5.3, 5.5, 5, 5.1, 5.3, 5.5, 6.7, 6.9, 5, 5.7, 4.9, 6.7, 4.9, 5.7, 6, 4.8, 4.9, 5.6, 5.8, 6.1, 6.4, 5.6, 5.1, 5.6, 6.1, 5.6, 5.5, 4.8, 5.4, 5.6, 5.1, 5.1, 5.9, 5.7, 5.2, 5, 5.2, 5.4, 5.1 ],
			'Petal.Width' => [ 0.2, 0.2, 0.2, 0.2, 0.2, 0.4, 0.3, 0.2, 0.2, 0.1, 0.2, 0.2, 0.1, 0.1, 0.2, 0.4, 0.4, 0.3, 0.3, 0.3, 0.2, 0.4, 0.2, 0.5, 0.2, 0.2, 0.4, 0.2, 0.2, 0.2, 0.2, 0.4, 0.1, 0.2, 0.2, 0.2, 0.2, 0.1, 0.2, 0.2, 0.3, 0.3, 0.2, 0.6, 0.4, 0.3, 0.2, 0.2, 0.2, 0.2, 1.4, 1.5, 1.5, 1.3, 1.5, 1.3, 1.6, 1, 1.3, 1.4, 1, 1.5, 1, 1.4, 1.3, 1.4, 1.5, 1, 1.5, 1.1, 1.8, 1.3, 1.5, 1.2, 1.3, 1.4, 1.4, 1.7, 1.5, 1, 1.1, 1, 1.2, 1.6, 1.5, 1.6, 1.5, 1.3, 1.3, 1.3, 1.2, 1.4, 1.2, 1, 1.3, 1.2, 1.3, 1.3, 1.1, 1.3, 2.5, 1.9, 2.1, 1.8, 2.2, 2.1, 1.7, 1.8, 1.8, 2.5, 2, 1.9, 2.1, 2, 2.4, 2.3, 1.8, 2.2, 2.3, 1.5, 2.3, 2, 2, 1.8, 2.1, 1.8, 1.8, 1.8, 2.1, 1.6, 1.9, 2, 2.2, 1.5, 1.4, 2.3, 2.4, 1.8, 1.8, 2.1, 2.4, 2.3, 1.9, 2.3, 2.5, 2.3, 1.9, 2, 2.3, 1.8 ],
		},
		by     => [ 'Species' ],
		agg    => { 'Sepal.Length' => 'mean', 'Sepal.Width' => 'mean', 'Petal.Length' => 'mean', 'Petal.Width' => 'mean' },
		skipna => 1,
		groups => [
			[ [ 'setosa' ], { 'Sepal.Length' => 5.0060000000000002, 'Sepal.Width' => 3.4279999999999999, 'Petal.Length' => 1.462, 'Petal.Width' => 0.246 } ],
			[ [ 'versicolor' ], { 'Sepal.Length' => 5.9359999999999999, 'Sepal.Width' => 2.77, 'Petal.Length' => 4.2599999999999998, 'Petal.Width' => 1.3260000000000001 } ],
			[ [ 'virginica' ], { 'Sepal.Length' => 6.5880000000000001, 'Sepal.Width' => 2.9740000000000002, 'Petal.Length' => 5.5519999999999996, 'Petal.Width' => 2.0259999999999998 } ],
		],
	},
	{
		name   => 'reg-tests-1a.R: aggregate.data.frame with a one-row result (NROW -> n)',
		cols   => [ 'a1', 'b1', 'a' ],
		data   => {
			'a1' => [ 2, 2, 2, 2, 2, 2, 2, 2, 2, 2 ],
			'b1' => [ 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a' ],
			'a' => [ 2, 2, 2, 2, 2, 2, 2, 2, 2, 2 ],
		},
		by     => [ 'a1', 'b1' ],
		agg    => { 'a' => 'n' },
		skipna => 1,
		groups => [
			[ [ 2, 'a' ], { 'a' => 10 } ],
		],
	},
	{
		name   => 'reg-tests-1a.R: aggregate(1:4, list(groups=f1), sum)',
		cols   => [ 'groups', 'x' ],
		data   => {
			'groups' => [ 'a', 'b', 'a', 'b' ],
			'x' => [ 1, 2, 3, 4 ],
		},
		by     => [ 'groups' ],
		agg    => { 'x' => 'sum' },
		skipna => 1,
		groups => [
			[ [ 'a' ], { 'x' => 4 } ],
			[ [ 'b' ], { 'x' => 6 } ],
		],
	},
	{
		name   => 'reg-tests-1c.R PR#15004: 21 grouping columns, groups not falsely merged',
		cols   => [ 'V1', 'V2', 'V3', 'V4', 'V5', 'V6', 'V7', 'V8', 'V9', 'V10', 'V11', 'V12', 'V13', 'V14', 'V15', 'V16', 'V17', 'V18', 'V19', 'V20', 'V21', 'x1', 'x2' ],
		data   => {
			'V1' => [ '1', '2', '3', '1', '2', '3', '1', '2', '3', '1' ],
			'V2' => [ '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000' ],
			'V3' => [ '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000' ],
			'V4' => [ '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000' ],
			'V5' => [ '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000' ],
			'V6' => [ '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000' ],
			'V7' => [ '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000' ],
			'V8' => [ '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000' ],
			'V9' => [ '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000' ],
			'V10' => [ '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000' ],
			'V11' => [ '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000' ],
			'V12' => [ '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000' ],
			'V13' => [ '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000' ],
			'V14' => [ '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000' ],
			'V15' => [ '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000' ],
			'V16' => [ '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000' ],
			'V17' => [ '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000' ],
			'V18' => [ '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000' ],
			'V19' => [ '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000' ],
			'V20' => [ '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000' ],
			'V21' => [ '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000' ],
			'x1' => [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ],
			'x2' => [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ],
		},
		by     => [ 'V1', 'V2', 'V3', 'V4', 'V5', 'V6', 'V7', 'V8', 'V9', 'V10', 'V11', 'V12', 'V13', 'V14', 'V15', 'V16', 'V17', 'V18', 'V19', 'V20', 'V21' ],
		agg    => { 'x1' => 'mean', 'x2' => 'mean' },
		skipna => 1,
		groups => [
			[ [ '1', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000' ], { 'x1' => 5.5, 'x2' => 5.5 } ],
			[ [ '2', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000' ], { 'x1' => 5, 'x2' => 5 } ],
			[ [ '3', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000', '10000' ], { 'x1' => 6, 'x2' => 6 } ],
		],
	},
	{
		name   => 'reg-tests-1c.R PR#15699: Y ~ 1, no grouping variables',
		cols   => [ 'Y', 'X' ],
		data   => {
			'Y' => [ 0.42783222952857614, 0.08678538305684924, 0.7758272818755358, 0.5362062873318791, 0.15541606000624597, 0.5959456085693091, 0.9674267389345914, 0.3816645343322307, 0.2906236252747476, 0.8405658835545182 ],
			'X' => [ 'B', 'B', 'A', 'A', 'B', 'C', 'B', 'C', 'A', 'C' ],
		},
		by     => [  ],
		agg    => { 'Y' => 'mean' },
		skipna => 1,
		groups => [
			[ [  ], { 'Y' => 0.50582936324644834 } ],
		],
	},
# END GENERATED (R)
);

my @PANDAS_CASES = (
# BEGIN GENERATED (pandas) -- python t/agg.R.pandas.py
	{
		name    => 'test_aggregate.py test_groupby_aggregation_mixed_dtype GH#6212 (dropna=False)',
		cols    => [ 'by1', 'by2', 'v1', 'v2' ],
		data    => {
			'by1' => [ 'red', 'blue', 1, 2, undef, 'big', 1, 2, 'red', 1, undef, 12 ],
			'by2' => [ 'wet', 'dry', 99, 95, undef, 'damp', 95, 99, 'red', 99, undef, undef ],
			'v1' => [ 1, 3, 5, 7, 8, 3, 5, undef, 4, 5, 7, 9 ],
			'v2' => [ 11, 33, 55, 77, 88, 33, 55, undef, 44, 55, 77, 99 ],
		},
		by      => [ 'by1', 'by2' ],
		agg     => { 'v1' => 'mean', 'v2' => 'mean' },
		skipna  => 1,
		ordered => 0,
		groups  => [
			[ [ 1, 95 ], { 'v1' => 5, 'v2' => 55 } ],
			[ [ 1, 99 ], { 'v1' => 5, 'v2' => 55 } ],
			[ [ 2, 95 ], { 'v1' => 7, 'v2' => 77 } ],
			[ [ 2, 99 ], { 'v1' => undef, 'v2' => undef } ],
			[ [ 12, undef ], { 'v1' => 9, 'v2' => 99 } ],
			[ [ 'big', 'damp' ], { 'v1' => 3, 'v2' => 33 } ],
			[ [ 'blue', 'dry' ], { 'v1' => 3, 'v2' => 33 } ],
			[ [ 'red', 'red' ], { 'v1' => 4, 'v2' => 44 } ],
			[ [ 'red', 'wet' ], { 'v1' => 1, 'v2' => 11 } ],
			[ [ undef, undef ], { 'v1' => 7.5, 'v2' => 82.5 } ],
		],
	},
	{
		name    => 'test_aggregate.py test_groupby_agg_dict_with_getitem GH#25471',
		cols    => [ 'A', 'B' ],
		data    => {
			'A' => [ 'A', 'A', 'B', 'B', 'B' ],
			'B' => [ 1, 2, 1, 1, 2 ],
		},
		by      => [ 'A' ],
		agg     => { 'B' => 'sum' },
		skipna  => 1,
		ordered => 1,
		groups  => [
			[ [ 'A' ], { 'B' => 3 } ],
			[ [ 'B' ], { 'B' => 4 } ],
		],
	},
	{
		name    => 'test_aggregate.py test_groupby_agg_dict_dup_columns GH#55006 (AoA, positions)',
		aoa     => [
			[ 1, 2, 3, 4 ],
			[ 1, 3, 4, 5 ],
			[ 2, 4, 5, 6 ],
		],
		by      => [ '0' ],
		agg     => { '1' => 'sum' },
		skipna  => 1,
		ordered => 1,
		groups  => [
			[ [ 1 ], { '1' => 5 } ],
			[ [ 2 ], { '1' => 4 } ],
		],
	},
	{
		name    => 'test_aggregate.py test_order_aggregate_multiple_funcs GH#25692 (without ohlc)',
		cols    => [ 'A', 'B' ],
		data    => {
			'A' => [ 1, 1, 2, 2 ],
			'B' => [ 1, 2, 3, 4 ],
		},
		by      => [ 'A' ],
		agg     => { 'B' => [ 'sum', 'max', 'mean', 'min' ] },
		skipna  => 1,
		ordered => 1,
		groups  => [
			[ [ 1 ], { 'B_sum' => 3, 'B_max' => 2, 'B_mean' => 1.5, 'B_min' => 1 } ],
			[ [ 2 ], { 'B_sum' => 7, 'B_max' => 4, 'B_mean' => 3.5, 'B_min' => 3 } ],
		],
	},
	{
		name    => 'test_aggregate.py test_agg_with_missing_values GH#58810 (ungrouped)',
		cols    => [ 'nan', 'values' ],
		data    => {
			'nan' => [ undef, undef, undef, undef ],
			'values' => [ 1, 2, 3, 4 ],
		},
		by      => [  ],
		agg     => { 'nan' => 'min', 'values' => 'sum' },
		skipna  => 1,
		ordered => 0,
		groups  => [
			[ [  ], { 'nan' => undef, 'values' => 10 } ],
		],
	},
	{
		name    => 'test_aggregate.py test_groupby_aggregate_empty_key GH#32580 ({c: [min]})',
		cols    => [ 'a', 'b', 'c' ],
		data    => {
			'a' => [ 1, 1, 2 ],
			'b' => [ 1, 2, 3 ],
			'c' => [ 1, 2, 4 ],
		},
		by      => [ 'a' ],
		agg     => { 'c' => 'min' },
		skipna  => 1,
		ordered => 1,
		groups  => [
			[ [ 1 ], { 'c' => 1 } ],
			[ [ 2 ], { 'c' => 4 } ],
		],
	},
	{
		name    => 'test_aggregate.py test_with_na_groups (dropna=False, len -> n)',
		cols    => [ 'label', 'v' ],
		data    => {
			'label' => [ undef, 'foo', 'bar', 'bar', undef, undef, 'bar', 'bar', undef, 'foo' ],
			'v' => [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
		},
		by      => [ 'label' ],
		agg     => { 'v' => 'n' },
		skipna  => 1,
		ordered => 1,
		groups  => [
			[ [ 'bar' ], { 'v' => 4 } ],
			[ [ 'foo' ], { 'v' => 2 } ],
			[ [ undef ], { 'v' => 4 } ],
		],
	},
	{
		name    => 'test_reductions.py test_basic_aggregations (float64; mean, std -> sd)',
		cols    => [ 'k', 'v' ],
		data    => {
			'k' => [ 0, 2, 2, 1, 2, 1, 1, 0, 0 ],
			'v' => [ 0, 2, 2, 1, 2, 1, 1, 0, 0 ],
		},
		by      => [ 'k' ],
		agg     => { 'v' => [ 'mean', 'sd' ] },
		skipna  => 1,
		ordered => 1,
		groups  => [
			[ [ 0 ], { 'v_mean' => 0, 'v_sd' => 0 } ],
			[ [ 1 ], { 'v_mean' => 1, 'v_sd' => 0 } ],
			[ [ 2 ], { 'v_mean' => 2, 'v_sd' => 0 } ],
		],
	},
	{
		name    => 'test_reductions.py test_mean_skipna GH#15675 (parametrisation 0: mean, skipna=True)',
		cols    => [ 'cat', 'val' ],
		data    => {
			'cat' => [ 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B' ],
			'val' => [ 0, 1, undef, 3, 4, 5, 6, 7, 8, 9 ],
		},
		by      => [ 'cat' ],
		agg     => { 'val' => 'mean' },
		skipna  => 1,
		ordered => 1,
		groups  => [
			[ [ 'A' ], { 'val' => 4.5 } ],
			[ [ 'B' ], { 'val' => 5 } ],
		],
	},
	{
		name    => 'test_reductions.py test_mean_skipna GH#15675 (parametrisation 0: mean, skipna=False)',
		cols    => [ 'cat', 'val' ],
		data    => {
			'cat' => [ 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B' ],
			'val' => [ 0, 1, undef, 3, 4, 5, 6, 7, 8, 9 ],
		},
		by      => [ 'cat' ],
		agg     => { 'val' => 'mean' },
		skipna  => 0,
		ordered => 1,
		groups  => [
			[ [ 'A' ], { 'val' => undef } ],
			[ [ 'B' ], { 'val' => 5 } ],
		],
	},
	{
		name    => 'test_reductions.py test_sum_skipna GH#15675 (parametrisation 0: sum, skipna=True)',
		cols    => [ 'cat', 'val' ],
		data    => {
			'cat' => [ 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B' ],
			'val' => [ 0, 1, undef, 3, 4, 5, 6, 7, 8, 9 ],
		},
		by      => [ 'cat' ],
		agg     => { 'val' => 'sum' },
		skipna  => 1,
		ordered => 1,
		groups  => [
			[ [ 'A' ], { 'val' => 18 } ],
			[ [ 'B' ], { 'val' => 25 } ],
		],
	},
	{
		name    => 'test_reductions.py test_sum_skipna GH#15675 (parametrisation 0: sum, skipna=False)',
		cols    => [ 'cat', 'val' ],
		data    => {
			'cat' => [ 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B' ],
			'val' => [ 0, 1, undef, 3, 4, 5, 6, 7, 8, 9 ],
		},
		by      => [ 'cat' ],
		agg     => { 'val' => 'sum' },
		skipna  => 0,
		ordered => 1,
		groups  => [
			[ [ 'A' ], { 'val' => undef } ],
			[ [ 'B' ], { 'val' => 25 } ],
		],
	},
	{
		name    => 'test_reductions.py test_multifunc_skipna GH#15675 (parametrisation 6: var, skipna=True)',
		cols    => [ 'cat', 'val' ],
		data    => {
			'cat' => [ 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B' ],
			'val' => [ 0, -1, 3, 4, undef, 5, 6, 7, 8, 9 ],
		},
		by      => [ 'cat' ],
		agg     => { 'val' => 'var' },
		skipna  => 1,
		ordered => 1,
		groups  => [
			[ [ 'A' ], { 'val' => 12.25 } ],
			[ [ 'B' ], { 'val' => 14.2 } ],
		],
	},
	{
		name    => 'test_reductions.py test_multifunc_skipna GH#15675 (parametrisation 6: var, skipna=False)',
		cols    => [ 'cat', 'val' ],
		data    => {
			'cat' => [ 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B' ],
			'val' => [ 0, -1, 3, 4, undef, 5, 6, 7, 8, 9 ],
		},
		by      => [ 'cat' ],
		agg     => { 'val' => 'var' },
		skipna  => 0,
		ordered => 1,
		groups  => [
			[ [ 'A' ], { 'val' => undef } ],
			[ [ 'B' ], { 'val' => 14.2 } ],
		],
	},
	{
		name    => 'test_reductions.py test_multifunc_skipna GH#15675 (parametrisation 9: var, skipna=True)',
		cols    => [ 'cat', 'val' ],
		data    => {
			'cat' => [ 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B' ],
			'val' => [ undef, undef, undef, undef, undef, undef, undef, undef, undef, undef ],
		},
		by      => [ 'cat' ],
		agg     => { 'val' => 'var' },
		skipna  => 1,
		ordered => 1,
		groups  => [
			[ [ 'A' ], { 'val' => undef } ],
			[ [ 'B' ], { 'val' => undef } ],
		],
	},
	{
		name    => 'test_reductions.py test_multifunc_skipna GH#15675 (parametrisation 9: var, skipna=False)',
		cols    => [ 'cat', 'val' ],
		data    => {
			'cat' => [ 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B' ],
			'val' => [ undef, undef, undef, undef, undef, undef, undef, undef, undef, undef ],
		},
		by      => [ 'cat' ],
		agg     => { 'val' => 'var' },
		skipna  => 0,
		ordered => 1,
		groups  => [
			[ [ 'A' ], { 'val' => undef } ],
			[ [ 'B' ], { 'val' => undef } ],
		],
	},
	{
		name    => 'test_reductions.py test_multifunc_skipna GH#15675 (parametrisation 12: std, skipna=True)',
		cols    => [ 'cat', 'val' ],
		data    => {
			'cat' => [ 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B' ],
			'val' => [ 0, 1, 3, -4, 5, 6, 7, -8, undef, 9 ],
		},
		by      => [ 'cat' ],
		agg     => { 'val' => 'sd' },
		skipna  => 1,
		ordered => 1,
		groups  => [
			[ [ 'A' ], { 'val' => 2.9860788111948193 } ],
			[ [ 'B' ], { 'val' => 6.978538528947161 } ],
		],
	},
	{
		name    => 'test_reductions.py test_multifunc_skipna GH#15675 (parametrisation 12: std, skipna=False)',
		cols    => [ 'cat', 'val' ],
		data    => {
			'cat' => [ 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B' ],
			'val' => [ 0, 1, 3, -4, 5, 6, 7, -8, undef, 9 ],
		},
		by      => [ 'cat' ],
		agg     => { 'val' => 'sd' },
		skipna  => 0,
		ordered => 1,
		groups  => [
			[ [ 'A' ], { 'val' => undef } ],
			[ [ 'B' ], { 'val' => 6.978538528947161 } ],
		],
	},
	{
		name    => 'test_reductions.py test_multifunc_skipna GH#15675 (parametrisation 15: std, skipna=True)',
		cols    => [ 'cat', 'val' ],
		data    => {
			'cat' => [ 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B' ],
			'val' => [ undef, undef, undef, undef, undef, undef, undef, undef, undef, undef ],
		},
		by      => [ 'cat' ],
		agg     => { 'val' => 'sd' },
		skipna  => 1,
		ordered => 1,
		groups  => [
			[ [ 'A' ], { 'val' => undef } ],
			[ [ 'B' ], { 'val' => undef } ],
		],
	},
	{
		name    => 'test_reductions.py test_multifunc_skipna GH#15675 (parametrisation 15: std, skipna=False)',
		cols    => [ 'cat', 'val' ],
		data    => {
			'cat' => [ 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B' ],
			'val' => [ undef, undef, undef, undef, undef, undef, undef, undef, undef, undef ],
		},
		by      => [ 'cat' ],
		agg     => { 'val' => 'sd' },
		skipna  => 0,
		ordered => 1,
		groups  => [
			[ [ 'A' ], { 'val' => undef } ],
			[ [ 'B' ], { 'val' => undef } ],
		],
	},
	{
		name    => 'test_reductions.py test_multifunc_skipna GH#15675 (parametrisation 24: min, skipna=True)',
		cols    => [ 'cat', 'val' ],
		data    => {
			'cat' => [ 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B' ],
			'val' => [ 0, -1, 3, 4, 5, -6, 7, undef, 8, 9 ],
		},
		by      => [ 'cat' ],
		agg     => { 'val' => 'min' },
		skipna  => 1,
		ordered => 1,
		groups  => [
			[ [ 'A' ], { 'val' => 0 } ],
			[ [ 'B' ], { 'val' => -6 } ],
		],
	},
	{
		name    => 'test_reductions.py test_multifunc_skipna GH#15675 (parametrisation 24: min, skipna=False)',
		cols    => [ 'cat', 'val' ],
		data    => {
			'cat' => [ 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B' ],
			'val' => [ 0, -1, 3, 4, 5, -6, 7, undef, 8, 9 ],
		},
		by      => [ 'cat' ],
		agg     => { 'val' => 'min' },
		skipna  => 0,
		ordered => 1,
		groups  => [
			[ [ 'A' ], { 'val' => 0 } ],
			[ [ 'B' ], { 'val' => undef } ],
		],
	},
	{
		name    => 'test_reductions.py test_multifunc_skipna GH#15675 (parametrisation 29: min, skipna=True)',
		cols    => [ 'cat', 'val' ],
		data    => {
			'cat' => [ 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B' ],
			'val' => [ undef, undef, undef, undef, undef, undef, undef, undef, undef, undef ],
		},
		by      => [ 'cat' ],
		agg     => { 'val' => 'min' },
		skipna  => 1,
		ordered => 1,
		groups  => [
			[ [ 'A' ], { 'val' => undef } ],
			[ [ 'B' ], { 'val' => undef } ],
		],
	},
	{
		name    => 'test_reductions.py test_multifunc_skipna GH#15675 (parametrisation 29: min, skipna=False)',
		cols    => [ 'cat', 'val' ],
		data    => {
			'cat' => [ 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B' ],
			'val' => [ undef, undef, undef, undef, undef, undef, undef, undef, undef, undef ],
		},
		by      => [ 'cat' ],
		agg     => { 'val' => 'min' },
		skipna  => 0,
		ordered => 1,
		groups  => [
			[ [ 'A' ], { 'val' => undef } ],
			[ [ 'B' ], { 'val' => undef } ],
		],
	},
	{
		name    => 'test_reductions.py test_multifunc_skipna GH#15675 (parametrisation 32: max, skipna=True)',
		cols    => [ 'cat', 'val' ],
		data    => {
			'cat' => [ 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B' ],
			'val' => [ 0, -1, 3, 4, 5, -6, 7, undef, 8, 9 ],
		},
		by      => [ 'cat' ],
		agg     => { 'val' => 'max' },
		skipna  => 1,
		ordered => 1,
		groups  => [
			[ [ 'A' ], { 'val' => 8 } ],
			[ [ 'B' ], { 'val' => 9 } ],
		],
	},
	{
		name    => 'test_reductions.py test_multifunc_skipna GH#15675 (parametrisation 32: max, skipna=False)',
		cols    => [ 'cat', 'val' ],
		data    => {
			'cat' => [ 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B' ],
			'val' => [ 0, -1, 3, 4, 5, -6, 7, undef, 8, 9 ],
		},
		by      => [ 'cat' ],
		agg     => { 'val' => 'max' },
		skipna  => 0,
		ordered => 1,
		groups  => [
			[ [ 'A' ], { 'val' => 8 } ],
			[ [ 'B' ], { 'val' => undef } ],
		],
	},
	{
		name    => 'test_reductions.py test_multifunc_skipna GH#15675 (parametrisation 37: max, skipna=True)',
		cols    => [ 'cat', 'val' ],
		data    => {
			'cat' => [ 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B' ],
			'val' => [ undef, undef, undef, undef, undef, undef, undef, undef, undef, undef ],
		},
		by      => [ 'cat' ],
		agg     => { 'val' => 'max' },
		skipna  => 1,
		ordered => 1,
		groups  => [
			[ [ 'A' ], { 'val' => undef } ],
			[ [ 'B' ], { 'val' => undef } ],
		],
	},
	{
		name    => 'test_reductions.py test_multifunc_skipna GH#15675 (parametrisation 37: max, skipna=False)',
		cols    => [ 'cat', 'val' ],
		data    => {
			'cat' => [ 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B' ],
			'val' => [ undef, undef, undef, undef, undef, undef, undef, undef, undef, undef ],
		},
		by      => [ 'cat' ],
		agg     => { 'val' => 'max' },
		skipna  => 0,
		ordered => 1,
		groups  => [
			[ [ 'A' ], { 'val' => undef } ],
			[ [ 'B' ], { 'val' => undef } ],
		],
	},
	{
		name    => 'test_reductions.py test_multifunc_skipna GH#15675 (parametrisation 40: median, skipna=True)',
		cols    => [ 'cat', 'val' ],
		data    => {
			'cat' => [ 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B' ],
			'val' => [ 0, -1, 3, 4, 5, -6, 7, undef, 8, 9 ],
		},
		by      => [ 'cat' ],
		agg     => { 'val' => 'median' },
		skipna  => 1,
		ordered => 1,
		groups  => [
			[ [ 'A' ], { 'val' => 5 } ],
			[ [ 'B' ], { 'val' => 1.5 } ],
		],
	},
	{
		name    => 'test_reductions.py test_multifunc_skipna GH#15675 (parametrisation 40: median, skipna=False)',
		cols    => [ 'cat', 'val' ],
		data    => {
			'cat' => [ 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B' ],
			'val' => [ 0, -1, 3, 4, 5, -6, 7, undef, 8, 9 ],
		},
		by      => [ 'cat' ],
		agg     => { 'val' => 'median' },
		skipna  => 0,
		ordered => 1,
		groups  => [
			[ [ 'A' ], { 'val' => 5 } ],
			[ [ 'B' ], { 'val' => undef } ],
		],
	},
	{
		name    => 'test_reductions.py test_multifunc_skipna GH#15675 (parametrisation 45: median, skipna=True)',
		cols    => [ 'cat', 'val' ],
		data    => {
			'cat' => [ 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B' ],
			'val' => [ undef, undef, undef, undef, undef, undef, undef, undef, undef, undef ],
		},
		by      => [ 'cat' ],
		agg     => { 'val' => 'median' },
		skipna  => 1,
		ordered => 1,
		groups  => [
			[ [ 'A' ], { 'val' => undef } ],
			[ [ 'B' ], { 'val' => undef } ],
		],
	},
	{
		name    => 'test_reductions.py test_multifunc_skipna GH#15675 (parametrisation 45: median, skipna=False)',
		cols    => [ 'cat', 'val' ],
		data    => {
			'cat' => [ 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B', 'A', 'B' ],
			'val' => [ undef, undef, undef, undef, undef, undef, undef, undef, undef, undef ],
		},
		by      => [ 'cat' ],
		agg     => { 'val' => 'median' },
		skipna  => 0,
		ordered => 1,
		groups  => [
			[ [ 'A' ], { 'val' => undef } ],
			[ [ 'B' ], { 'val' => undef } ],
		],
	},
	{
		name    => 'test_reductions.py test_cython_median (dropna=False)',
		cols    => [ 'lab', 'x' ],
		data    => {
			'lab' => [ undef, 13, 5, 14, 20, 40, 22, 4, 16, 30, 40, 36, 49, 9, 44, 2, 27, undef, 10, 32, 15, 28, 13, 7, 37, 21, 33, 33, 47, 21, 10, 31, 46, 48, undef, 34, 19, 19, 1, 9, 16, 17, 28, 25, 34, 44, 43, 38, 48, 15, 45, undef, 11, 23, 28, 34, 35, 5, 23, 5, 47, 10, 22, 44, 26, 33, 24, 42, undef, 32, 22, 20, 29, 25, 39, 29, 23, 43, 10, 21, 24, 44, 22, 30, 3, undef, 22, 24, 4, 34, 31, 16, 38, 26, 2, 10, 12, 5, 25, 1, 26, 35, undef, 22, 13, 44, 16, 41, 22, 19, 34, 48, 39, 29, 5, 38, 39, 20, 18, undef, 49, 8, 24, 9, 39, 30, 7, 5, 4, 0, 42, 41, 18, 4, 13, 22, undef, 24, 30, 31, 31, 25, 22, 46, 41, 37, 2, 28, 44, 30, 9, 25, 27, undef, 27, 11, 5, 34, 49, 27, 4, 2, 39, 14, 24, 46, 12, 39, 4, 0, undef, 14, 24, 0, 30, 41, 25, 5, 41, 2, 25, 49, 17, 22, 12, 15, 11, undef, 36, 19, 49, 18, 39, 26, 31, 0, 43, 7, 48, 10, 38, 22, 38, 15, undef, 30, 0, 14, 33, 45, 23, 48, 14, 2, 34, 10, 48, 28, 48, 38, 34, undef, 41, 9, 4, 22, 5, 33, 49, 45, 46, 43, 12, 39, 12, 2, 38, 48, undef, 30, 47, 4, 5, 12, 3, 31, 2, 19, 25, 22, 29, 40, 44, 41, 37, undef, 29, 39, 23, 20, 41, 48, 18, 30, 2, 48, 40, 2, 18, 44, 31, 27, undef, 35, 31, 9, 23, 27, 27, 14, 25, 5, 29, 0, 1, 45, 41, 33, 23, undef, 21, 12, 9, 23, 26, 40, 26, 5, 5, 48, 7, 47, 31, 12, 21, 32, undef, 18, 19, 34, 31, 4, 36, 23, 42, 29, 26, 31, 19, 34, 15, 44, 35, undef, 43, 7, 46, 19, 18, 28, 1, 48, 42, 35, 5, 36, 18, 48, 38, 13, undef, 12, 29, 21, 22, 14, 43, 32, 3, 47, 0, 7, 8, 25, 41, 33, 4, undef, 28, 45, 11, 36, 21, 44, 40, 5, 13, 9, 8, 3, 42, 41, 21, 48, undef, 0, 33, 39, 34, 36, 27, 45, 48, 13, 13, 35, 11, 11, 30, 3, 7, undef, 32, 2, 36, 34, 27, 14, 9, 24, 8, 44, 44, 12, 49, 23, 25, 17, undef, 9, 11, 23, 23, 9, 46, 39, 33, 30, 46, 14, 11, 48, 2, 17, 3, undef, 45, 36, 42, 13, 4, 0, 1, 44, 11, 47, 7, 8, 13, 7, 27, 21, undef, 29, 40, 49, 43, 48, 41, 49, 17, 12, 40, 29, 29, 21, 20, 11, 6, undef, 9, 8, 16, 17, 36, 4, 8, 7, 26, 2, 49, 31, 11, 24, 7, 12, undef, 26, 46, 21, 43, 32, 43, 46, 11, 17, 40, 32, 8, 10, 15, 46, 32, undef, 40, 7, 48, 12, 47, 7, 32, 8, 42, 15, 34, 41, 17, 22, 33, 13, undef, 20, 14, 13, 5, 36, 26, 2, 45, 14, 11, 16, 15, 9, 49, 36, 29, undef, 31, 15, 16, 2, 48, 37, 30, 18, 21, 32, 22, 10, 17, 1, 21, 16, undef, 38, 13, 41, 28, 17, 24, 42, 0, 2, 10, 26, 20, 12, 18, 21, 15, undef, 21, 44, 0, 15, 39, 47, 38, 5, 6, 21, 0, 22, 33, 35, 7, 17, undef, 24, 2, 3, 49, 15, 17, 36, 26, 5, 21, 23, 47, 11, 4, 8, 7, undef, 22, 40, 24, 34, 1, 18, 10, 19, 36, 36, 41, 30, 29, 45, 43, 45, undef, 24, 16, 32, 27, 27, 1, 15, 48, 22, 22, 36, 42, 27, 33, 31, 33, undef, 13, 47, 39, 38, 31, 6, 18, 40, 11, 45, 48, 40, 9, 17, 6, 18, undef, 12, 38, 2, 6, 23, 28, 42, 16, 38, 25, 33, 34, 42, 1, 32, 24, undef, 27, 40, 39, 18, 37, 44, 36, 16, 9, 4, 9, 36, 43, 5, 19, 43, undef, 20, 40, 39, 7, 2, 41, 27, 0, 33, 35, 6, 42, 30, 24, 7, 7, undef, 22, 18, 46, 30, 29, 6, 13, 9, 49, 39, 19, 35, 29, 22, 36, 14, undef, 34, 43, 23, 49, 15, 41, 43, 37, 10, 23, 40, 36, 30, 1, 32, 2, undef, 38, 37, 41, 44, 24, 46, 47, 12, 43, 8, 37, 44, 39, 10, 10, 11, undef, 40, 41, 48, 22, 42, 30, 25, 33, 18, 10, 49, 6, 36, 5, 31, 8, undef, 42, 9, 5, 0, 12, 45, 7, 11, 24, 8, 42, 29, 24, 10, 9, 27, undef, 47, 30, 43, 44, 12, 29, 45, 47, 19, 40, 26, 18, 16, 39, 49, 32, undef, 19, 36, 39, 30, 46, 34, 23, 5, 32, 26, 10, 49, 14, 28, 8, 9, undef, 2, 27, 16, 3, 37, 48, 1, 21, 2, 46, 32, 19, 44, 25, 21, 3, undef, 25, 12, 25, 13, 14, 23, 21, 10, 47, 22, 20, 7, 31, 46, 1, 32, undef, 4, 11, 9, 48, 41, 32, 18, 48, 13, 29, 1, 48, 33, 23, 28, 41, undef, 26, 8, 20, 37, 37, 41, 43, 41, 49, 37, 22, 22, 41, 2, 27, 32, undef, 1, 36, 4, 3, 20, 45, 6, 4, 22, 22, 42, 12, 8, 18, 39, 35, undef, 17, 1, 48, 21, 15, 35, 12, 36, 3, 13, 16, 40, 46, 18, 1, 10, undef, 25, 31, 30, 24, 41, 18, 33, 17, 4, 12, 28, 16, 17, 27, 35, 3, undef, 3, 32, 13, 39, 24, 2, 13, 0, 28, 44, 3, 44, 20, 8, 43, 46, undef, 20, 39, 25, 41, 23, 13, 16, 12, 44, 26, 30, 48, 46, 32, 31, 5, undef, 19, 25, 12, 23, 28, 28, 37, 0, 32, 38, 39, 6, 43, 47, 36, 2, undef, 35, 23, 38, 23, 27, 14, 4, 18, 40, 42, 16, 31, 14 ],
			'x' => [ undef, -0.5227484414807474, undef, -2.4414673826398556, undef, 1.1441658720372287, undef, 0.7738065867276614, undef, -0.5538228364240524, undef, -0.31055654665915255, undef, -0.7921467553588982, undef, -0.09919805171738795, undef, -0.6071856998706371, undef, -0.8922740434297903, undef, 0.18803508698068597, undef, 0.41050391297026284, undef, 0.7831809961440773, undef, -1.6384425032355252, undef, -1.50483141386432, undef, 0.12871565747406846, undef, 0.722430872307499, undef, 0.28403814525037085, undef, 0.8684602112115102, undef, -0.4218588261783162, undef, 1.8014208584493328, undef, -1.0790604591369424, undef, 0.9692722011381628, undef, 1.324347019236957, undef, 1.128523141900478, undef, -1.4186656898014849, undef, 1.2157576351945363, undef, 0.99970142215178, undef, 0.2739322545923299, undef, -0.7710521598195307, undef, -0.19673006635772372, undef, -0.1052597784150319, undef, -1.0663396121649127, undef, -2.4338766971489387, undef, 0.07379335958326627, undef, -0.00895629811039896, undef, 0.477929298799656, undef, -1.2541866619736308, undef, 1.766779317484588, undef, 0.4163865350301778, undef, -0.6897195637660919, undef, -0.10462645267369168, undef, -0.13412851934954786, undef, 0.19004583859111193, undef, -0.8360851661432465, undef, -0.6676199486614574, undef, -0.8363865253041882, undef, 0.047404412494126226, undef, -0.7028878955725052, undef, -0.8211599492508597, undef, -0.2629696110774594, undef, 0.9084019250927495, undef, 2.457336522342424, undef, -0.456333893932018, undef, -1.0472180935940827, undef, -0.955144769724686, undef, -1.9683967522378658, undef, -0.15824761527156533, undef, 1.6784190387621596, undef, 0.04580783577937577, undef, -0.04336259016175258, undef, 0.7247764935410931, undef, -0.6677563797627329, undef, -0.5320653277786109, undef, -0.5915748828912161, undef, 0.6909519446056412, undef, -0.8083458775593314, undef, -0.44445682570554373, undef, -0.048723544625703656, undef, -0.9361621531378327, undef, 0.20169530087063778, undef, 0.3532885925705412, undef, 0.662004970148938, undef, 1.7224233963662954, undef, 1.0972650368859622, undef, 0.4289462445148908, undef, -0.4868890686859325, undef, -0.3170749669346225, undef, 0.7476554288062055, undef, -0.08748148289345688, undef, -0.8046461065088295, undef, -2.121825972601985, undef, -0.23963819232902653, undef, 0.948376210637088, undef, 0.22100096632251784, undef, 0.3104215762864059, undef, -0.8847733337672445, undef, 0.5078871822065824, undef, 0.12194944967029515, undef, 1.1363151482568636, undef, -1.1035907500633413, undef, 0.10185328474395018, undef, 1.52520308017327, undef, -0.2824272472716989, undef, -2.0322793065134026, undef, 0.8664070590018645, undef, -0.7102141913075584, undef, 1.9586147276154673, undef, -1.1206776631652569, undef, -1.8785474803883646, undef, -0.5819546491605353, undef, -0.8494743678230212, undef, 0.3002730904204611, undef, -1.9738130282047839, undef, 1.2942116284105942, undef, 0.06712070250380273, undef, 0.737900169928009, undef, 0.2803458736422704, undef, 1.1878533083569829, undef, -1.3013535202249853, undef, 0.7225065897534976, undef, -1.9043559061435325, undef, 0.557511373399325, undef, -1.7905532669844222, undef, -0.588318953093688, undef, 2.845645074509526, undef, 0.9537367314931017, undef, 0.649461273978431, undef, 0.10653270157752616, undef, -1.2856051436646596, undef, 0.5251415978751188, undef, 0.1597236640001516, undef, -0.8460837686653659, undef, -1.7763653849182433, undef, 0.7601562085524842, undef, 0.6411281903517326, undef, -0.4691213318717145, undef, -1.2483778102356926, undef, 0.8521407722678009, undef, -0.7660172081897683, undef, -1.4420539027685755, undef, -1.2942387751632807, undef, -1.0248226241279634, undef, -1.3311571805649849, undef, -0.9661408777268591, undef, -0.29488942970262855, undef, 1.5268961098463931, undef, -0.25289920168642466, undef, -0.6888972645408504, undef, 0.5494769624409097, undef, 0.755385523473681, undef, -2.685595289652432, undef, -0.4738225196184616, undef, -1.0671774923126214, undef, 0.5070958053657446, undef, 2.6261738286185947, undef, 1.1532309938411287, undef, 0.2709257789707485, undef, -1.9108997779424512, undef, 0.7621685717133088, undef, 0.6039910508652822, undef, -0.8387668539743595, undef, 1.3438063203968533, undef, -0.04637066919387357, undef, 1.4672068853838773, undef, -0.09506466916037241, undef, 0.440622290368524, undef, -1.2415651857429464, undef, -1.7383665131115047, undef, 2.2185418386340072, undef, 0.1382874588248894, undef, -0.9846256772614974, undef, -1.0969368989183785, undef, -0.5942490563115667, undef, 0.6842415849945397, undef, -1.7912308228410456, undef, 0.7629952676464102, undef, 0.2297891839639593, undef, 0.14322291081554303, undef, 0.03644802049061874, undef, -0.2077935782605395, undef, -1.6176592423461078, undef, -0.0590182437964927, undef, 0.45766891877208543, undef, 1.2661073627611317, undef, 0.2738849009141932, undef, -1.23607514405535, undef, 1.2119933423122224, undef, -0.20093216091699778, undef, -1.117239240902205, undef, -0.5873795214394222, undef, -0.49462626280097816, undef, 1.1793321763349756, undef, 0.9253908755239111, undef, -2.1610333505271506, undef, 0.006729381639104526, undef, -1.647385270167446, undef, 0.12652469722762597, undef, -0.10383958550657135, undef, -0.977425550328532, undef, -0.44553532113848804, undef, -0.9888192773432133, undef, 0.5759881685469587, undef, 0.3827033305295286, undef, -0.3461423935879244, undef, 0.5399169566568177, undef, 0.33071151034490437, undef, -0.5699415008227597, undef, -1.250820892910365, undef, 0.8073369080982529, undef, 1.7813206828903434, undef, -0.9568919886003732, undef, -0.06919425535493127, undef, -1.942934292422628, undef, 0.2919958479014126, undef, 0.5549073291632637, undef, -0.4697956074007749, undef, -0.2806581622889455, undef, -0.36005498048912127, undef, -1.4506170874306672, undef, 0.18411775561425542, undef, -0.4403392056116025, undef, -0.8519621895254362, undef, 0.3267159033813245, undef, 3.056342448576572, undef, 0.12733000408860684, undef, -0.3997797846506893, undef, -0.4788113807596332, undef, 1.1418162824452363, undef, 1.0354934939748968, undef, 2.736458725862448, undef, -0.9409262342036953, undef, -1.2930451619066796, undef, -0.9980278030069736, undef, -0.695339730098914, undef, 1.449347374642348, undef, -0.5516409984891103, undef, -1.5151477943471543, undef, -0.9057348401478296, undef, -0.1939005756185201, undef, 0.6112916946490713, undef, -0.2233288441794942, undef, -0.8283509853404322, undef, 0.4669249482525825, undef, -1.219476167503311, undef, 0.09420101341934806, undef, -0.6534090705331795, undef, -0.4342191613258609, undef, 0.8333912121455666, undef, -0.10009046486167383, undef, 0.11348010352709692, undef, 1.0255631696971512, undef, 0.26301255606830115, undef, -1.1296835823802003, undef, -0.5285487871678283, undef, -0.3636101787076367, undef, 0.6263471527745221, undef, -0.7658286038917371, undef, 0.47317784613006036, undef, -1.1214539869093503, undef, -0.3641609994000157, undef, -0.5414528840700396, undef, -0.45572827030158114, undef, 0.7918690820955161, undef, 0.44343906735833705, undef, -0.6104175090232179, undef, 0.8749562515109941, undef, -0.5521424065645414, undef, 1.8088449628587848, undef, -0.1328044743386139, undef, -1.5297999957110904, undef, 0.28842181160931923, undef, 1.1615503604811854, undef, -0.9620737434554694, undef, -0.42732062653522446, undef, -0.14556942539588308, undef, 1.4740974764405594, undef, 1.2607733727219834, undef, -0.20790081666281907, undef, 0.7366646118639338, undef, -0.16391876009902318, undef, 0.03528656963620903, undef, -0.5559339779395361, undef, 0.08364267122819928, undef, -0.5558396885780594, undef, 0.313835120636449, undef, 0.2043963634083679, undef, 0.13074649659237508, undef, 0.39938547889431975, undef, -0.7084067849532787, undef, -0.6275626738045664, undef, -0.668271701024572, undef, 1.2004887538923004, undef, -0.3717423549172949, undef, 0.5394025169930706, undef, 0.5851115504218798, undef, 1.3383289912756622, undef, -0.47537841071405834, undef, -1.6806406063719657, undef, -0.883751559732829, undef, -0.48163454666281014, undef, -0.1030345310149255, undef, 0.2309384811096597, undef, -1.2891630274820416, undef, 1.417302420445751, undef, 0.5614143189164458, undef, -1.5622149607842444, undef, 1.4716817014732062, undef, -0.834124292834502, undef, -1.8934479125719303, undef, 0.4878139172904151, undef, 0.18862497042534201, undef, -1.126843200549746, undef, -0.23812341199355797, undef, -1.3418828847586879, undef, 0.22009507394198313, undef, -0.7028042433878099, undef, 0.40342012908269265, undef, -0.09142686767339213, undef, 0.39257185055724303, undef, -1.8230142215967522, undef, 0.21113360860988503, undef, 2.8630989884726206, undef, -1.2337626990106572, undef, -0.1808335583004662, undef, -1.0332863893232653, undef, -0.4426744608336864, undef, -0.4475713869940921, undef, 0.1579041657291662, undef, -1.0574242166772603, undef, -0.6434339124687553, undef, 1.2609835038667203, undef, -0.6465143725591912, undef, 0.8914495412790282, undef, 0.13995585012127032, undef, 0.3112146214841731, undef, -0.7060629239114831, undef, 0.04358892769528479, undef, 0.13612545006316243, undef, -0.021721857920632182, undef, -0.7772023247948056, undef, 0.8785058405216716, undef, -0.8410267720078337, undef, 1.5112977055292913, undef, 1.1578488998139589, undef, 0.0013119551237214442, undef, -1.8599673513879968, undef, 0.7828548483383695, undef, -0.5933074765515483, undef, 1.6007125542072596, undef, -1.3333640534167832, undef, -0.3931576415089246, undef, 0.16011555993879759, undef, 2.4005445693384204, undef, 0.4724457980298689, undef, 0.784322087164067, undef, 0.5866738388147025, undef, -1.4191819757591058, undef, -0.1984120606031994, undef, 0.13609173374937553, undef, 1.3232574876465875, undef, -2.2003616163374757, undef, -0.7105945319425023, undef, 0.41013590165116603, undef, -0.3757345965787546, undef, 1.0870054953546335, undef, 0.2767953811830683, undef, -0.11242830377589233, undef, -0.7417626257805382, undef, -0.7136704942172495, undef, 0.8273312048150304, undef, 1.184129100789156, undef, -2.1065611872332948, undef, -0.5686805406396525, undef, -1.3581751007544167, undef, -0.2582727096422166, undef, -0.25432262563549546, undef, -2.342921928027927, undef, -0.3034726649944876, undef, 0.3064120818344737, undef, -2.173997513558657, undef, -1.6767091476623874, undef, 0.12015624637066263, undef, 1.190060670481847, undef, -0.7633915728919575, undef, 1.087701697239807, undef, 0.5437886476464773, undef, 1.0293720976482779, undef, -0.4078493336446891, undef, 0.5901489837909252, undef, 0.9928014195750838, undef, 0.513245588103384, undef, -1.6965975324834899, undef, -0.06470749582998864, undef, -0.03021406010653926, undef, 0.9438880984894495, undef, -0.2354101467042596, undef, -1.1335466735510225, undef, 1.2330731451429207, undef, 0.9223126265204882, undef, 0.7697552393057158, undef, 0.5638630194844192, undef, -1.0043795138814626, undef, 0.9148204828660309, undef, -0.7048950413848644, undef, 1.316431753311868, undef, -1.3539295571708072, undef, -2.125527883275941, undef, -0.45404092214596675, undef, -0.42027139605492014, undef, 0.16778475442037846, undef, 1.488961584822809, undef, 0.10055350242187855, undef, -0.023635120294927363, undef, -1.9257157098517275, undef, -0.5351769370888788, undef, 0.32504482003104374, undef, 0.2384032404677032, undef, 0.31169434489336684, undef, -0.20449984904689955, undef, 0.8735804873101571, undef, 0.15546925398579745, undef, -0.12701123624878183, undef, 0.7200106451844424, undef, 1.295381571439326, undef, -0.3973992333893161, undef, 0.40359895439285454, undef, -0.8413112957218758, undef, 1.3948218448617127, undef, -1.511898084178987, undef, -0.22797429875882258, undef, 0.2834153216360066, undef, 1.2105037494650055, undef, -0.08911600672401215, undef, -1.7779605845691213, undef, 0.41083879461758455, undef, -1.1889031941887371, undef, 0.9344695067976221, undef, 1.37502569046117, undef, 0.20080300496543788, undef, 0.3097533305949396, undef, 0.5359671059623131, undef, 0.6752704900364216, undef, 0.9404036383030467, undef, -1.0430206947590754, undef, 0.00830672431640463, undef, -0.45070090702216814, undef, 0.28157907700644214, undef, 2.441132835692758, undef, 2.523750556565919, undef, 0.3031228169389775, undef, 0.09656039054564472, undef, -0.7337658313823371, undef, -1.0145953036373696, undef, -0.2716605495854419, undef, 0.5728123025961991, undef, -0.1691529815213515, undef, 0.1879194118872056, undef, 0.26908106282207145, undef, -0.04632293555458984, undef, -1.981880044445124, undef, 0.3161567504689509, undef, 1.1311759870554547, undef, 0.36995112234128474, undef, -0.2060109159819667, undef, 0.93181455440129, undef, 0.24263038529759048, undef, 1.3777329642259921, undef, -0.06067719796995602, undef, -0.9077565769370638, undef, 0.5960610883780224, undef, 0.06933870156706443, undef, 0.6151956063139694, undef, -0.7661634456406518, undef, -0.4368536553707516, undef, -0.9188751137092982, undef, 0.443581034342539, undef, 0.8562454750365031, undef, -0.5110760069421925, undef, 0.32038533115964973, undef, 0.7420753165903624, undef, 0.30697742860820487, undef, 0.412981823340592, undef, -1.0908515170593922, undef, -1.653863845908707, undef, 0.38059724486327584, undef, -0.7023309977826528, undef, 0.6871254281866361, undef, 1.5638256535648178, undef, -0.8772704091738562, undef, 0.08543088159552167, undef, -1.430215056158942, undef, -0.5889053006974968, undef, -1.0049396051530344, undef, -0.25682363961240373, undef, 1.5766481244409924, undef, 0.7155157207978142, undef, 3.110154571856014, undef, 1.2551571761141604, undef, 0.26077995320951547, undef, 1.162407533463749, undef, -1.3222780137924612, undef, -1.158040158755948, undef, 0.9218953645230186, undef, 0.7838359722911195, undef, -0.044231737907907444, undef, 1.876453379846786, undef, -0.9119616386922705, undef, 1.1999969427458774, undef, -0.47024369076662825 ],
		},
		by      => [ 'lab' ],
		agg     => { 'x' => 'median' },
		skipna  => 1,
		ordered => 1,
		groups  => [
			[ [ 0 ], { 'x' => 0.1269273506581164 } ],
			[ [ 1 ], { 'x' => -0.004224753056612865 } ],
			[ [ 2 ], { 'x' => 0.18225596167358274 } ],
			[ [ 3 ], { 'x' => -0.48163454666281014 } ],
			[ [ 4 ], { 'x' => -0.43061405740051206 } ],
			[ [ 5 ], { 'x' => -0.2778502240367691 } ],
			[ [ 6 ], { 'x' => 0.5728123025961991 } ],
			[ [ 7 ], { 'x' => -0.24597185148877196 } ],
			[ [ 8 ], { 'x' => -0.7035908470795456 } ],
			[ [ 9 ], { 'x' => -0.25289920168642466 } ],
			[ [ 10 ], { 'x' => 0.047404412494126226 } ],
			[ [ 11 ], { 'x' => 0.0736465919126345 } ],
			[ [ 12 ], { 'x' => 0.3064120818344737 } ],
			[ [ 13 ], { 'x' => 0.44343906735833705 } ],
			[ [ 14 ], { 'x' => -0.47024369076662825 } ],
			[ [ 15 ], { 'x' => -0.1030345310149255 } ],
			[ [ 16 ], { 'x' => -0.43605989885417845 } ],
			[ [ 17 ], { 'x' => -0.4403392056116025 } ],
			[ [ 18 ], { 'x' => 0.6771104881461398 } ],
			[ [ 19 ], { 'x' => -0.5942490563115667 } ],
			[ [ 20 ], { 'x' => -0.6104175090232179 } ],
			[ [ 21 ], { 'x' => -0.10009046486167383 } ],
			[ [ 22 ], { 'x' => 0.557511373399325 } ],
			[ [ 23 ], { 'x' => 0.5549073291632637 } ],
			[ [ 24 ], { 'x' => -0.35106630757944157 } ],
			[ [ 25 ], { 'x' => 0.4289462445148908 } ],
			[ [ 26 ], { 'x' => -0.7733003583058733 } ],
			[ [ 27 ], { 'x' => -0.06585661040068216 } ],
			[ [ 28 ], { 'x' => 0.6797560375154806 } ],
			[ [ 29 ], { 'x' => -1.0912457099733208 } ],
			[ [ 30 ], { 'x' => -0.23812341199355797 } ],
			[ [ 31 ], { 'x' => -0.8911229609015994 } ],
			[ [ 32 ], { 'x' => -0.0670537285397764 } ],
			[ [ 33 ], { 'x' => 0.13612545006316243 } ],
			[ [ 34 ], { 'x' => 0.1922958238361247 } ],
			[ [ 35 ], { 'x' => 0.443581034342539 } ],
			[ [ 36 ], { 'x' => 0.18945918151513175 } ],
			[ [ 37 ], { 'x' => 0.7677927287295476 } ],
			[ [ 38 ], { 'x' => -0.05732934378814027 } ],
			[ [ 39 ], { 'x' => 0.32038533115964973 } ],
			[ [ 40 ], { 'x' => -0.6434339124687553 } ],
			[ [ 41 ], { 'x' => 0.06933870156706443 } ],
			[ [ 42 ], { 'x' => 0.0830987769832867 } ],
			[ [ 43 ], { 'x' => 1.6007125542072596 } ],
			[ [ 44 ], { 'x' => -0.1052597784150319 } ],
			[ [ 45 ], { 'x' => -0.5310707363560748 } ],
			[ [ 46 ], { 'x' => -0.16437709952651935 } ],
			[ [ 47 ], { 'x' => -0.3717423549172949 } ],
			[ [ 48 ], { 'x' => 0.06712070250380273 } ],
			[ [ 49 ], { 'x' => -0.6152583335938964 } ],
			[ [ undef ], { 'x' => -0.20093216091699778 } ],
		],
	},
	{
		name    => 'test_reductions.py test_nunique',
		cols    => [ 'A', 'B', 'C' ],
		data    => {
			'A' => [ 'a', 'b', 'b', 'a', 'c', 'c' ],
			'B' => [ 'a', 'b', 'x', 'a', 'c', 'c' ],
			'C' => [ 'a', 'b', 'b', 'a', 'c', 'x' ],
		},
		by      => [ 'A' ],
		agg     => { 'B' => 'nunique', 'C' => 'nunique' },
		skipna  => 1,
		ordered => 1,
		groups  => [
			[ [ 'a' ], { 'B' => 1, 'C' => 1 } ],
			[ [ 'b' ], { 'B' => 2, 'C' => 1 } ],
			[ [ 'c' ], { 'B' => 1, 'C' => 2 } ],
		],
	},
	{
		name    => 'test_reductions.py test_nunique (x replaced by None, dropna)',
		cols    => [ 'A', 'B', 'C' ],
		data    => {
			'A' => [ 'a', 'b', 'b', 'a', 'c', 'c' ],
			'B' => [ 'a', 'b', undef, 'a', 'c', 'c' ],
			'C' => [ 'a', 'b', 'b', 'a', 'c', undef ],
		},
		by      => [ 'A' ],
		agg     => { 'B' => 'nunique', 'C' => 'nunique' },
		skipna  => 1,
		ordered => 1,
		groups  => [
			[ [ 'a' ], { 'B' => 1, 'C' => 1 } ],
			[ [ 'b' ], { 'B' => 1, 'C' => 1 } ],
			[ [ 'c' ], { 'B' => 1, 'C' => 1 } ],
		],
	},
	{
		name    => 'test_nth.py test_first_last_with_None_expanded GH#32800/38286 (first, case 0)',
		cols    => [ 'id', 'value' ],
		data    => {
			'id' => [ 'a', 'a', 'a' ],
			'value' => [ undef, 'foo', undef ],
		},
		by      => [ 'id' ],
		agg     => { 'value' => 'first' },
		skipna  => 1,
		ordered => 1,
		groups  => [
			[ [ 'a' ], { 'value' => 'foo' } ],
		],
	},
	{
		name    => 'test_nth.py test_first_last_with_None_expanded GH#32800/38286 (last, case 0)',
		cols    => [ 'id', 'value' ],
		data    => {
			'id' => [ 'a', 'a', 'a' ],
			'value' => [ undef, 'foo', undef ],
		},
		by      => [ 'id' ],
		agg     => { 'value' => 'last' },
		skipna  => 1,
		ordered => 1,
		groups  => [
			[ [ 'a' ], { 'value' => 'foo' } ],
		],
	},
	{
		name    => 'test_nth.py test_first_last_with_None_expanded GH#32800/38286 (first, case 1)',
		cols    => [ 'id', 'value' ],
		data    => {
			'id' => [ 'a' ],
			'value' => [ undef ],
		},
		by      => [ 'id' ],
		agg     => { 'value' => 'first' },
		skipna  => 1,
		ordered => 1,
		groups  => [
			[ [ 'a' ], { 'value' => undef } ],
		],
	},
	{
		name    => 'test_nth.py test_first_last_with_None_expanded GH#32800/38286 (last, case 1)',
		cols    => [ 'id', 'value' ],
		data    => {
			'id' => [ 'a' ],
			'value' => [ undef ],
		},
		by      => [ 'id' ],
		agg     => { 'value' => 'last' },
		skipna  => 1,
		ordered => 1,
		groups  => [
			[ [ 'a' ], { 'value' => undef } ],
		],
	},
# END GENERATED (pandas)
);

# a group's key tuple as one string, undef kept distinct from every value
sub tkey { join "\x1f", map { defined $_ ? "v$_" : 'u' } @_ }

# the reducers whose answer is one of the inputs or an exact integer
my %EXACT = map { $_ => 1 } qw(n count nunique sum min max median first last);

sub same_value {
	my ($got, $want, $func, $what) = @_;
	if (!defined $want) { ok(!defined $got, "$what is undef") or diag("got $got"); return }
	if (!defined $got)  { fail("$what is defined"); diag("expected $want"); return }
	# a sum of non-integers is not exact; neither is a median that averages two
	my $exact = $EXACT{$func} && ($func ne 'sum' && $func ne 'median'
	            || $want == int $want);
	if ($exact) { is("$got", "$want", "$what") ; return }
	my $rel = $want == 0 ? abs $got : abs(($got - $want) / $want);
	$worst = $rel if $rel > $worst;
	ok($rel <= $RTOL, "$what within $RTOL") or diag("got $got, expected $want, rel $rel");
}

# the four shapes of a case's frame; the AoA one comes with its columns'
# positions
sub shapes {
	my ($case) = @_;
	return ( AoA => [ $case->{aoa}, undef ] ) if $case->{aoa};
	my ($cols, $hoa) = @{$case}{qw(cols data)};
	my $n = @{ $hoa->{ $cols->[0] } };
	my @aoh = map { my $i = $_; +{ map { $_ => $hoa->{$_}[$i] } @$cols } } 0 .. $n - 1;
	my %hoh = map { (sprintf('r%05d', $_) => $aoh[$_]) } 0 .. $n - 1;   # key order = row order
	my @aoa = map { my $i = $_; [ map { $hoa->{$_}[$i] } @$cols ] } 0 .. $n - 1;
	my %pos; @pos{@$cols} = 0 .. $#$cols;
	return ( HoA => [ $hoa, undef ], AoH => [ \@aoh, undef ], HoH => [ \%hoh, undef ],
	         AoA => [ \@aoa, \%pos ] );
}

sub run_case {
	my ($case, $ref) = @_;
	my %shape = shapes($case);
	for my $sh (sort keys %shape) {
		my ($df, $pos) = @{ $shape{$sh} };
		my $id = $pos ? sub { $pos->{ $_[0] } } : sub { $_[0] };
		my @by = map { $id->($_) } @{ $case->{by} };
		my %spec = map { $id->($_) => $case->{agg}{$_} } keys %{ $case->{agg} };
		# expected output name -> [ name agg() gives this shape, its reducer ]
		my %out;
		for my $c (keys %{ $case->{agg} }) {
			my $f = $case->{agg}{$c};
			my @f = ref $f ? @$f : ($f);
			for my $fn (@f) {
				my $name = @f > 1 ? "${c}_$fn" : $c;
				$out{$name} = [ @f > 1 ? $id->($c) . "_$fn" : $id->($c), $fn ];
			}
		}
		my $what = "$ref $case->{name} [$sh]";
		my $got = agg($df, by => (@by ? \@by : undef), agg => \%spec,
		              skipna => $case->{skipna}, 'output_type' => 'aoh');
		my %got = map { (tkey(@{$_}{@by}) => $_) } @$got;
		is(scalar @$got, scalar @{ $case->{groups} }, "$what: group count");
		if ($case->{ordered}) {
			is_deeply([ map { tkey(@{$_}{@by}) } @$got ],
			          [ map { tkey(@{ $_->[0] }) } @{ $case->{groups} } ],
			          "$what: group order");
		}
		for my $g (@{ $case->{groups} }) {
			my ($keys, $vals) = @$g;
			my $label = join(', ', map { defined $_ ? $_ : 'undef' } @$keys);
			my $row = $got{ tkey(@$keys) };
			ok($row, "$what: group ($label) present") or next;
			for my $o (sort keys %$vals) {
				my ($name, $fn) = @{ $out{$o} };
				same_value($row->{$name}, $vals->{$o}, $fn, "$what: ($label) $o");
			}
		}
	}
}

run_case($_, 'R')      for @R_CASES;
run_case($_, 'pandas') for @PANDAS_CASES;
diag(sprintf 'worst relative difference: %.3g', $worst) if $ENV{TEST_VERBOSE};

# reg-tests-1d.R PR#17283 pins its answer itself, to the tolerance it states
{
	my ($case) = grep { $_->{name} =~ /PR#17283/ } @R_CASES;
	my $got = agg($case->{data}, by => [qw(Region Cold)], agg => { Population => 'mean' },
	              'output_type' => 'aoh', sort => 0);
	my @pop = map { $_->{Population} } sort {
		# R's order: Cold varies slowest, Region fastest, both in level order
		my %lev = (Northeast => 0, South => 1, 'North Central' => 2, West => 3);
		$a->{Cold} cmp $b->{Cold} || $lev{ $a->{Region} } <=> $lev{ $b->{Region} }
	} @$got;
	my @want = (8802.8, 4208.12, 7233.83, 4582.57, 1360.5, 2372.17, 970.167);
	is(scalar @pop, scalar @want, 'reg-tests-1d.R PR#17283: seven groups');
	# all.equal(target, current, tolerance = 1e-6) is one test over the whole
	# vector: mean(abs(target - current)) / mean(abs(target)), all.equal.numeric
	my ($dev, $tot) = (0, 0);
	for my $i (0 .. $#want) { $dev += abs($pop[$i] - $want[$i]); $tot += abs $pop[$i] }
	cmp_ok($dev / $tot, '<', 1e-6,
		'reg-tests-1d.R PR#17283: matches its pinned values to all.equal 1e-6');
}

# ---- errors pandas raises too ------------------------------------------------
# test_aggregate.py test_func_duplicates_raises GH#28426: the same reducer twice
# names two output columns alike, which pandas refuses ("Function names must be
# unique").  agg() refuses it for every named output; see the divergence below
# for aoa.
throws_ok { agg({ A => [0, 0, 1, 1], B => [1, 2, 3, 4] }, by => 'A',
                agg => { B => [ 'min', 'min' ] }) }
	qr/generated twice: B_min/, 'pandas GH#28426: duplicate reducer names die';

# ---- divergences, pinned so that changing one is a deliberate act ------------
{
	# pandas' default dropna=True, and R's default for a non-factor key, drop a
	# group whose key is missing.  agg() keeps it, as the frozen dropna=False /
	# exclude = "" answers above show; here is the group they would drop.
	my ($case) = grep { $_->{name} =~ /test_with_na_groups/ } @PANDAS_CASES;
	my $got = agg($case->{data}, by => 'label', agg => { v => 'n' }, 'output_type' => 'aoh');
	is_deeply($got->[-1], { label => undef, v => 4 },
		'divergence: an undef key is a group, sorted last (pandas dropna=True drops it)');

	# GH#6212's by1 mixes numbers and strings.  pandas sorts the numbers first;
	# agg() compares a column that is not all numbers as strings throughout.
	($case) = grep { $_->{name} =~ /GH#6212/ } @PANDAS_CASES;
	$got = agg($case->{data}, by => [qw(by1 by2)], agg => { v1 => 'mean' }, 'output_type' => 'aoa');
	is_deeply([ map { $_->[0] } @$got ],
		[ 1, 1, 12, 2, 2, 'big', 'blue', 'red', 'red', undef ],
		'divergence: a mixed key column sorts as strings (pandas puts 2 before 12)');

	# GH#28426 again: under output_type aoa the columns are positional, so a
	# repeated reducer names nothing twice and is allowed
	$got = agg([ [0, 1], [0, 2], [1, 3], [1, 4] ], by => 0, agg => { 1 => [ 'min', 'min' ] });
	is_deeply($got, [ [0, 1, 1], [1, 3, 3] ],
		'divergence: a repeated reducer is allowed for aoa output (pandas raises)');

	# test_aggregate.py test_groupby_aggregate_empty_key GH#32580, second
	# parametrisation: pandas ignores {b => []}; agg() refuses an empty list
	throws_ok { agg({ a => [1, 1, 2], b => [1, 2, 3], c => [1, 2, 4] }, by => 'a',
	                agg => { b => [], c => ['min'] }) }
		qr/empty aggregator list for column 'b'/,
		'divergence: an empty reducer list dies (pandas GH#32580 skips it)';

	# test_reductions.py test_nunique with dropna=False counts None as a value;
	# agg()'s nunique counts defined cells only, which is dropna=True
	($case) = grep { $_->{name} =~ /test_nunique \(x replaced/ } @PANDAS_CASES;
	$got = agg($case->{data}, by => 'A', agg => { B => 'nunique' }, 'output_type' => 'aoh');
	is($got->[1]{B}, 1, 'divergence: nunique ignores undef (pandas dropna=False gives 2 for b)');
}

done_testing();
