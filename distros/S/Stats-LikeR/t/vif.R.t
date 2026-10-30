#!/usr/bin/env perl
# vif() against car 3.1-5's vif().
#
# PROVENANCE
#
# t/vif.R.R, committed beside this file, generated every literal in %DATA and
# @R_CASES, and $STATECRIME_URBAN, under R 4.6.1 (2026-06-24) with car 3.1-5
# and carData 3.0-6 at options(digits = 17).  Re-run it with
#     Rscript t/vif.R.R
# This test never invokes R; it reads the frozen literals.
#
# Each expected value is car::vif() at its default type = "terms", on:
#
#   Duncan       car's own examples, man/vif.Rd: prestige ~ income +
#                education; + type, a 3-level factor and so a GVIF table; and
#                (income + education)*type, written out here as its
#                expansion, because this module's formulas take no
#                parentheses
#   mtcars       the formulas TODO.md listed as failing through 0.3217: an
#                interaction (wt*hp), a removed term that is not in the model
#                (- disp, the shape of car's y ~ x1 + x2 - x3) and one that
#                is (- qsec), and '.'; then a model with no intercept
#   warpbreaks   breaks ~ wool * tension (?warpbreaks), factors crossed
#   airquality   Ozone ~ Solar.R + Wind + Temp, where car's model drops a
#                row missing the response as well as one missing a predictor
#
# and one value from statsmodels 0.14.6, stats/tests/test_outliers_influence.py,
# test_reset_stata(): Stata's VIF of 16.4394 for urban among the seven columns
# of statsmodels' statecrime data, taken with no constant.  The generator
# recomputes it in R, as 1 / (1 - R^2) with R^2 uncentred, from the same CSV.
#
# WHAT IT PINS
#
# Through 0.3217 vif() split the right-hand side on '+' and regressed each
# piece on the others.  An interaction, a removed term, '.', a factor and
# '- 1' all died, with lm()'s "0 degrees of freedom" or "need at least two
# predictors"; and the response's missing values did not take rows out.  Of
# the ten cases below, 0.3217 got the first right, died on the next eight,
# and gave airquality's VIFs over the 146 rows that have Solar.R rather than
# car's 111 (Solar.R 1.0893 for car's 1.0953).  Now each term gets car's
# value, multi-df terms get car's GVIF, Df and GVIF^(1/(2*Df)), and each of
# car's two warnings, and both of its refusals, has its counterpart.
#
# TOLERANCE
#
# 1e-11 relative.  The worst disagreement observed on the double build is
# 2.9e-14, on the Duncan interaction model, whose GVIFs reach 1234: a VIF is a
# diagonal element of an inverse, and its rounding error grows with the
# inverse's condition number.  The well-conditioned cases agree to a few ulp.
# The diag() below the loop reports the worst on every run.  The data are
# 17-digit decimals of R's doubles, which a wider NV reads as slightly
# different numbers, at a relative distance of at most 2^-53 per value.
# Across the nine perls of ./test.all.perls.pl on 2026-10-17 the worst was
# 3.8e-14, on the i686 and x87 builds; the long-double and quadmath perls
# were at 1.7e-14.  That leaves over 250-fold headroom.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Test::LeakTrace 'no_leaks_ok';
use Stats::LikeR qw(vif lm);

my $TOL = 1e-11;

my %DATA = (
	Duncan => {
		'type' => [ 'prof', 'prof', 'prof', 'prof', 'prof', 'prof', 'prof', 'prof', 'wc', 'prof', 'prof', 'prof', 'prof', 'prof', 'prof', 'wc', 'prof', 'prof', 'prof', 'prof', 'wc', 'wc', 'wc', 'wc', 'bc', 'bc', 'bc', 'bc', 'bc', 'bc', 'bc', 'bc', 'bc', 'bc', 'bc', 'bc', 'bc', 'bc', 'bc', 'bc', 'bc', 'bc', 'bc', 'bc', 'bc' ],
		'income' => [ 62, 72, 75, 55, 64, 21, 64, 80, 67, 72, 42, 76, 76, 41, 48, 76, 53, 60, 42, 78, 29, 48, 55, 29, 21, 47, 81, 36, 22, 44, 15, 7, 42, 9, 21, 21, 16, 16, 9, 14, 12, 17, 7, 34, 8 ],
		'education' => [ 86, 76, 92, 90, 86, 84, 93, 100, 87, 86, 74, 98, 97, 84, 91, 34, 45, 56, 44, 82, 72, 55, 71, 50, 23, 39, 28, 32, 22, 25, 29, 7, 26, 19, 15, 20, 26, 28, 17, 22, 30, 25, 20, 47, 32 ],
		'prestige' => [ 82, 83, 90, 76, 90, 87, 93, 90, 52, 88, 57, 89, 97, 59, 73, 38, 76, 81, 45, 92, 39, 34, 41, 16, 33, 53, 67, 57, 26, 29, 10, 15, 19, 10, 13, 24, 20, 7, 3, 16, 6, 11, 8, 41, 10 ],
	},
	mtcars => {
		'mpg' => [ 21, 21, 22.800000000000001, 21.399999999999999, 18.699999999999999, 18.100000000000001, 14.300000000000001, 24.399999999999999, 22.800000000000001, 19.199999999999999, 17.800000000000001, 16.399999999999999, 17.300000000000001, 15.199999999999999, 10.4, 10.4, 14.699999999999999, 32.399999999999999, 30.399999999999999, 33.899999999999999, 21.5, 15.5, 15.199999999999999, 13.300000000000001, 19.199999999999999, 27.300000000000001, 26, 30.399999999999999, 15.800000000000001, 19.699999999999999, 15, 21.399999999999999 ],
		'wt' => [ 2.6200000000000001, 2.875, 2.3199999999999998, 3.2149999999999999, 3.4399999999999999, 3.46, 3.5699999999999998, 3.1899999999999999, 3.1499999999999999, 3.4399999999999999, 3.4399999999999999, 4.0700000000000003, 3.73, 3.7799999999999998, 5.25, 5.4240000000000004, 5.3449999999999998, 2.2000000000000002, 1.615, 1.835, 2.4649999999999999, 3.52, 3.4350000000000001, 3.8399999999999999, 3.8450000000000002, 1.9350000000000001, 2.1400000000000001, 1.5129999999999999, 3.1699999999999999, 2.77, 3.5699999999999998, 2.7799999999999998 ],
		'hp' => [ 110, 110, 93, 110, 175, 105, 245, 62, 95, 123, 123, 180, 180, 180, 205, 215, 230, 66, 52, 65, 97, 150, 150, 245, 175, 66, 91, 113, 264, 175, 335, 109 ],
		'disp' => [ 160, 160, 108, 258, 360, 225, 360, 146.69999999999999, 140.80000000000001, 167.59999999999999, 167.59999999999999, 275.80000000000001, 275.80000000000001, 275.80000000000001, 472, 460, 440, 78.700000000000003, 75.700000000000003, 71.099999999999994, 120.09999999999999, 318, 304, 350, 400, 79, 120.3, 95.099999999999994, 351, 145, 301, 121 ],
		'qsec' => [ 16.460000000000001, 17.02, 18.609999999999999, 19.440000000000001, 17.02, 20.219999999999999, 15.84, 20, 22.899999999999999, 18.300000000000001, 18.899999999999999, 17.399999999999999, 17.600000000000001, 18, 17.98, 17.82, 17.420000000000002, 19.469999999999999, 18.52, 19.899999999999999, 20.010000000000002, 16.870000000000001, 17.300000000000001, 15.41, 17.050000000000001, 18.899999999999999, 16.699999999999999, 16.899999999999999, 14.5, 15.5, 14.6, 18.600000000000001 ],
	},
	warpbreaks => {
		'breaks' => [ 26, 30, 54, 25, 70, 52, 51, 26, 67, 18, 21, 29, 17, 12, 18, 35, 30, 36, 36, 21, 24, 18, 10, 43, 28, 15, 26, 27, 14, 29, 19, 29, 31, 41, 20, 44, 42, 26, 19, 16, 39, 28, 21, 39, 29, 20, 21, 24, 17, 13, 15, 15, 16, 28 ],
		'wool' => [ 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B' ],
		'tension' => [ 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H' ],
	},
	airquality => {
		'Ozone' => [ 41, 36, 12, 18, undef, 28, 23, 19, 8, undef, 7, 16, 11, 14, 18, 14, 34, 6, 30, 11, 1, 11, 4, 32, undef, undef, undef, 23, 45, 115, 37, undef, undef, undef, undef, undef, undef, 29, undef, 71, 39, undef, undef, 23, undef, undef, 21, 37, 20, 12, 13, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, 135, 49, 32, undef, 64, 40, 77, 97, 97, 85, undef, 10, 27, undef, 7, 48, 35, 61, 79, 63, 16, undef, undef, 80, 108, 20, 52, 82, 50, 64, 59, 39, 9, 16, 78, 35, 66, 122, 89, 110, undef, undef, 44, 28, 65, undef, 22, 59, 23, 31, 44, 21, 9, undef, 45, 168, 73, undef, 76, 118, 84, 85, 96, 78, 73, 91, 47, 32, 20, 23, 21, 24, 44, 21, 28, 9, 13, 46, 18, 13, 24, 16, 13, 23, 36, 7, 14, 30, undef, 14, 18, 20 ],
		'Solar.R' => [ 190, 118, 149, 313, undef, undef, 299, 99, 19, 194, undef, 256, 290, 274, 65, 334, 307, 78, 322, 44, 8, 320, 25, 92, 66, 266, undef, 13, 252, 223, 279, 286, 287, 242, 186, 220, 264, 127, 273, 291, 323, 259, 250, 148, 332, 322, 191, 284, 37, 120, 137, 150, 59, 91, 250, 135, 127, 47, 98, 31, 138, 269, 248, 236, 101, 175, 314, 276, 267, 272, 175, 139, 264, 175, 291, 48, 260, 274, 285, 187, 220, 7, 258, 295, 294, 223, 81, 82, 213, 275, 253, 254, 83, 24, 77, undef, undef, undef, 255, 229, 207, 222, 137, 192, 273, 157, 64, 71, 51, 115, 244, 190, 259, 36, 255, 212, 238, 215, 153, 203, 225, 237, 188, 167, 197, 183, 189, 95, 92, 252, 220, 230, 259, 236, 259, 238, 24, 112, 237, 224, 27, 238, 201, 238, 14, 139, 49, 20, 193, 145, 191, 131, 223 ],
		'Wind' => [ 7.4000000000000004, 8, 12.6, 11.5, 14.300000000000001, 14.9, 8.5999999999999996, 13.800000000000001, 20.100000000000001, 8.5999999999999996, 6.9000000000000004, 9.6999999999999993, 9.1999999999999993, 10.9, 13.199999999999999, 11.5, 12, 18.399999999999999, 11.5, 9.6999999999999993, 9.6999999999999993, 16.600000000000001, 9.6999999999999993, 12, 16.600000000000001, 14.9, 8, 12, 14.9, 5.7000000000000002, 7.4000000000000004, 8.5999999999999996, 9.6999999999999993, 16.100000000000001, 9.1999999999999993, 8.5999999999999996, 14.300000000000001, 9.6999999999999993, 6.9000000000000004, 13.800000000000001, 11.5, 10.9, 9.1999999999999993, 8, 13.800000000000001, 11.5, 14.9, 20.699999999999999, 9.1999999999999993, 11.5, 10.300000000000001, 6.2999999999999998, 1.7, 4.5999999999999996, 6.2999999999999998, 8, 8, 10.300000000000001, 11.5, 14.9, 8, 4.0999999999999996, 9.1999999999999993, 9.1999999999999993, 10.9, 4.5999999999999996, 10.9, 5.0999999999999996, 6.2999999999999998, 5.7000000000000002, 7.4000000000000004, 8.5999999999999996, 14.300000000000001, 14.9, 14.9, 14.300000000000001, 6.9000000000000004, 10.300000000000001, 6.2999999999999998, 5.0999999999999996, 11.5, 6.9000000000000004, 9.6999999999999993, 11.5, 8.5999999999999996, 8, 8.5999999999999996, 12, 7.4000000000000004, 7.4000000000000004, 7.4000000000000004, 9.1999999999999993, 6.9000000000000004, 13.800000000000001, 7.4000000000000004, 6.9000000000000004, 7.4000000000000004, 4.5999999999999996, 4, 10.300000000000001, 8, 8.5999999999999996, 11.5, 11.5, 11.5, 9.6999999999999993, 11.5, 10.300000000000001, 6.2999999999999998, 7.4000000000000004, 10.9, 10.300000000000001, 15.5, 14.300000000000001, 12.6, 9.6999999999999993, 3.3999999999999999, 8, 5.7000000000000002, 9.6999999999999993, 2.2999999999999998, 6.2999999999999998, 6.2999999999999998, 6.9000000000000004, 5.0999999999999996, 2.7999999999999998, 4.5999999999999996, 7.4000000000000004, 15.5, 10.9, 10.300000000000001, 10.9, 9.6999999999999993, 14.9, 15.5, 6.2999999999999998, 10.9, 11.5, 6.9000000000000004, 13.800000000000001, 10.300000000000001, 10.300000000000001, 8, 12.6, 9.1999999999999993, 10.300000000000001, 10.300000000000001, 16.600000000000001, 6.9000000000000004, 13.199999999999999, 14.300000000000001, 8, 11.5 ],
		'Temp' => [ 67, 72, 74, 62, 56, 66, 65, 59, 61, 69, 74, 69, 66, 68, 58, 64, 66, 57, 68, 62, 59, 73, 61, 61, 57, 58, 57, 67, 81, 79, 76, 78, 74, 67, 84, 85, 79, 82, 87, 90, 87, 93, 92, 82, 80, 79, 77, 72, 65, 73, 76, 77, 76, 76, 76, 75, 78, 73, 80, 77, 83, 84, 85, 81, 84, 83, 83, 88, 92, 92, 89, 82, 73, 81, 91, 80, 81, 82, 84, 87, 85, 74, 81, 82, 86, 85, 82, 86, 88, 86, 83, 81, 81, 81, 82, 86, 85, 87, 89, 90, 90, 92, 86, 86, 82, 80, 79, 77, 79, 76, 78, 78, 77, 72, 75, 79, 81, 86, 88, 97, 94, 96, 94, 91, 92, 93, 93, 87, 84, 80, 78, 75, 73, 81, 76, 77, 71, 71, 78, 67, 76, 68, 82, 64, 71, 81, 69, 63, 70, 77, 75, 76, 68 ],
	},
);

# [ frame, formula, warns, rows used, [ term, GVIF, Df ] ... ]: warns is
# 'interactions' or 'intercept' for the message car gives, '' for none
my @R_CASES = (
	[ 'Duncan', 'prestige ~ income + education', '', 45, [ 'income', 2.1049004710947665, 1 ], [ 'education', 2.1049004710947665, 1 ] ],
	[ 'Duncan', 'prestige ~ income + education + type', '', 45, [ 'income', 2.2091779795013635, 1 ], [ 'education', 5.2975837124265759, 1 ], [ 'type', 5.0985918566076949, 2 ] ],
	[ 'Duncan', 'prestige ~ income + education + type + income:type + education:type', 'interactions', 45, [ 'income', 4.8244380228906785, 1 ], [ 'education', 32.778424268234886, 1 ], [ 'type', 480.93123747987642, 2 ], [ 'income:type', 176.24440296542488, 2 ], [ 'education:type', 1233.7463162008448, 2 ] ],
	[ 'mtcars', 'mpg ~ wt*hp + disp', 'interactions', 32, [ 'wt', 12.778516147050082, 1 ], [ 'hp', 19.691007070344195, 1 ], [ 'disp', 7.3559453816438145, 1 ], [ 'wt:hp', 43.241604426123615, 1 ] ],
	[ 'mtcars', 'mpg ~ wt + hp - disp', '', 32, [ 'wt', 1.7666245792682798, 1 ], [ 'hp', 1.7666245792682798, 1 ] ],
	[ 'mtcars', 'mpg ~ wt + hp + disp + qsec - qsec', '', 32, [ 'wt', 4.8446175259187862, 1 ], [ 'hp', 2.7366326916912329, 1 ], [ 'disp', 7.3245171503633975, 1 ] ],
	[ 'mtcars', 'mpg ~ .', '', 32, [ 'wt', 6.9169415712643501, 1 ], [ 'hp', 5.1667583082157291, 1 ], [ 'disp', 7.9854390249980058, 1 ], [ 'qsec', 3.1331191093370894, 1 ] ],
	[ 'mtcars', 'mpg ~ wt + hp + disp - 1', 'intercept', 32, [ 'wt', 16.700825053974519, 1 ], [ 'hp', 13.487569692012999, 1 ], [ 'disp', 19.914970479280608, 1 ] ],
	[ 'warpbreaks', 'breaks ~ wool * tension', 'interactions', 54, [ 'wool', 2.9999999999999978, 1 ], [ 'tension', 3.9999999999999982, 2 ], [ 'wool:tension', 8.0000000000000018, 2 ] ],
	[ 'airquality', 'Ozone ~ Solar.R + Wind + Temp', '', 111, [ 'Solar.R', 1.0952528194296984, 1 ], [ 'Wind', 1.3290700366790171, 1 ], [ 'Temp', 1.4313668951347054, 1 ] ],

);

my %WARNING = (
	interactions => qr/^vif: there are higher-order terms \(interactions\) in this model$/,
	intercept    => qr/^vif: No intercept: vifs may not be sensible\.$/,
);

# vif() with its warnings collected rather than fatal
sub vif_warned {
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	my $v = vif(@_);
	return ($v, \@w);
}

my ($worst, $worst_at) = (0, '');
sub rel_ok {
	my ($got, $want, $name) = @_;
	my $err = abs($got - $want) / abs($want);
	ok($err <= $TOL, $name) or diag(sprintf "  got %.17g\n  want %.17g", $got, $want);
	($worst, $worst_at) = ($err, $name) if $err > $worst;
}

for my $c (@R_CASES) {
	my ($frame, $formula, $warns, $n, @terms) = @$c;
	my ($v, $w) = vif_warned($DATA{$frame}, $formula);
	my $table = grep { $_->[2] > 1 } @terms;   # car returns a table when any term has Df > 1
	is_deeply([ sort keys %$v ], [ sort map { $_->[0] } @terms ], "$frame, $formula: car's terms");
	for my $t (@terms) {
		my ($term, $gvif, $df) = @$t;
		if ($table) {
			rel_ok($v->{$term}{GVIF}, $gvif, "$frame, $formula: GVIF of $term");
			is($v->{$term}{Df}, $df, "$frame, $formula: Df of $term");
			rel_ok($v->{$term}{'GVIF^(1/(2*Df))'}, $gvif ** (1 / (2 * $df)),
				"$frame, $formula: GVIF^(1/(2*Df)) of $term");
		} else {
			ok(!ref $v->{$term}, "$frame, $formula: $term is a plain number, as car's vector is");
			rel_ok($v->{$term}, $gvif, "$frame, $formula: VIF of $term");
		}
	}
	my @want = $warns eq '' ? () : map { $WARNING{$_} } split /,/, $warns;
	is(scalar @$w, scalar @want, "$frame, $formula: as many warnings as car gives");
	like($w->[$_], $want[$_], "$frame, $formula: car's warning, $warns") for 0 .. $#want;
	# the rows car's model has, missing response and all
	is(Stats::LikeR::_vif_design($DATA{$frame}, $formula)->{n}, $n, "$frame, $formula: $n complete rows");
}
diag(sprintf 'worst relative error vs car::vif(): %.2g (%s)', $worst, $worst_at);

# The array-reference form, and a one-sided formula, name the predictors
# without a response; the values are the formula form's.
{
	my %by;
	for my $c (@R_CASES) { $by{"$c->[0] $c->[1]"} = { map { $_->[0] => $_->[1] } @$c[4 .. $#$c] } }
	my $mt = $by{'mtcars mpg ~ wt + hp + disp + qsec - qsec'};
	my $dn = $by{'Duncan prestige ~ income + education + type'};
	for my $spec ([qw(wt hp disp)], '~ wt + hp + disp') {
		my $v = vif($DATA{mtcars}, $spec);
		my $what = ref $spec ? 'an array of names' : 'a one-sided formula';
		rel_ok($v->{$_}, $mt->{$_}, "mtcars, $what: VIF of $_") for sort keys %$mt;
	}
	my $v = vif($DATA{Duncan}, [qw(income education type)]);
	rel_ok($v->{$_}{GVIF}, $dn->{$_}, "Duncan, an array of names with a factor: GVIF of $_") for sort keys %$dn;
	# a response missing on a row takes the row out only when there is one
	is(Stats::LikeR::_vif_design($DATA{airquality}, '~ Solar.R + Wind + Temp')->{n},
		146, 'airquality without its response: the 146 rows with Solar.R');
}

# statsmodels' test_reset_stata(): urban's VIF among the seven statecrime
# columns, no constant.  Stata's 16.4394 is pinned to four decimals there.
{
	my %sc = (
		violent => [ 459.9, 632.6, 423.2, 530.3, 473.4, 340.9, 300.5, 645.1, 1348.9, 612.6, 432.6, 274.1, 238.5, 618.2, 366.4, 294.5, 412.0, 265.5, 628.4, 119.9, 590.0, 465.6, 504.4, 214.2, 306.7, 500.3, 283.9, 305.5, 704.6, 169.5, 311.3, 652.8, 385.5, 414.0, 223.6, 358.1, 510.4, 261.2, 388.9, 254.3, 675.1, 201.0, 666.0, 491.4, 216.2, 135.1, 230.0, 338.3, 331.2, 259.7, 219.3 ],
		murder => [ 7.1, 3.2, 5.5, 6.3, 5.4, 3.2, 3.0, 4.6, 24.2, 5.5, 6.0, 1.8, 1.5, 8.4, 5.3, 1.3, 4.7, 4.3, 12.3, 2.0, 7.7, 2.7, 6.3, 1.5, 6.9, 6.6, 3.2, 2.5, 5.9, 0.9, 3.7, 10.0, 4.0, 5.4, 2.0, 5.0, 6.5, 2.3, 5.4, 3.0, 6.7, 3.6, 7.4, 5.4, 1.4, 1.3, 4.7, 2.8, 4.9, 2.6, 2.0 ],
		hs_grad => [ 82.1, 91.4, 84.2, 82.4, 80.6, 89.3, 88.6, 87.4, 87.1, 85.3, 83.9, 90.4, 88.4, 86.4, 86.6, 90.5, 89.7, 81.7, 82.2, 90.2, 88.2, 89.0, 87.9, 91.5, 80.4, 86.8, 90.8, 89.8, 83.9, 91.3, 87.4, 82.8, 84.7, 84.3, 90.1, 87.6, 85.6, 89.1, 87.9, 84.7, 83.6, 89.9, 83.1, 79.9, 90.4, 91.0, 86.6, 89.7, 82.8, 89.8, 91.8 ],
		poverty => [ 17.5, 9.0, 16.5, 18.8, 14.2, 12.9, 9.4, 10.8, 18.4, 14.9, 16.5, 10.4, 14.3, 13.3, 14.4, 11.8, 13.4, 18.6, 17.3, 12.3, 9.1, 10.3, 16.2, 11.0, 21.9, 14.6, 15.1, 12.3, 12.4, 8.5, 9.4, 18.0, 14.2, 16.3, 11.7, 15.2, 16.2, 14.3, 12.5, 11.5, 17.1, 14.2, 17.1, 17.2, 11.5, 11.4, 10.5, 12.3, 17.7, 12.4, 9.8 ],
		single => [ 29.0, 25.5, 25.7, 26.3, 27.8, 21.4, 25.0, 27.6, 48.0, 26.6, 29.3, 26.3, 19.0, 26.0, 24.5, 20.3, 22.8, 25.4, 31.4, 22.0, 27.3, 25.0, 25.6, 20.2, 32.8, 25.3, 20.3, 20.9, 28.5, 19.5, 25.8, 29.1, 30.2, 26.3, 18.2, 26.3, 25.9, 22.7, 24.5, 27.3, 28.4, 20.8, 26.3, 27.6, 17.9, 21.3, 24.0, 22.2, 23.3, 22.2, 18.9 ],
		white => [ 70, 68.3, 80, 78.4, 62.7, 84.6, 79.1, 71.9, 38.7, 76.9, 61.9, 26.9, 92.3, 72.5, 85.7, 92.3, 86.3, 88.8, 63.7, 94.9, 60.2, 82.4, 79.9, 87.4, 59.6, 83.9, 89.4, 88.1, 76.2, 94.5, 70.7, 72.5, 67.4, 70.5, 90.2, 84, 75.4, 85.6, 83.5, 82.6, 67.6, 86.3, 79.1, 73.8, 89.3, 95.8, 70.4, 80.2, 94.3, 88.4, 91.3 ],
		urban => [ 48.65, 44.46, 80.07, 39.54, 89.73, 76.86, 84.83, 68.71, 100, 87.44, 65.38, 71.46, 50.51, 79.97, 59.17, 41.66, 50.17, 40.99, 61.33, 26.21, 83.53, 90.3, 66.37, 58, 27.62, 56.61, 26.49, 53.78, 86.51, 47.34, 92.24, 53.75, 82.66, 54.88, 40, 65.31, 45.79, 62.47, 70.68, 90.46, 55.78, 29.92, 54.38, 75.35, 81.17, 17.38, 69.79, 74.97, 33.2, 55.8, 24.51 ],

	);
	my $STATECRIME_URBAN = 16.439430136828548;
	my ($v, $w) = vif_warned(\%sc, '~ violent + murder + hs_grad + poverty + single + white + urban - 1');
	rel_ok($v->{urban}, $STATECRIME_URBAN, 'statecrime, no constant: urban, as R computes it');
	ok(abs($v->{urban} - 16.4394) < 5e-5, "statecrime, no constant: urban is Stata's 16.4394 to four decimals");
	is(scalar @$w, 1, 'statecrime: one warning');
	like($w->[0], $WARNING{intercept}, 'statecrime: the no-intercept warning');
}

# car's refusals: "model contains fewer than 2 terms" and "there are aliased
# coefficients in the model", the second here naming the column.
throws_ok { vif($DATA{mtcars}, 'mpg ~ wt') } qr/^vif: model contains fewer than 2 terms$/m,
	'one term is refused, as car refuses it';
throws_ok { vif($DATA{mtcars}, ['wt']) } qr/^vif: model contains fewer than 2 terms$/m,
	'one name is refused';
throws_ok { vif($DATA{mtcars}, []) } qr/^vif: model contains fewer than 2 terms$/m,
	'no names are refused';
throws_ok { vif($DATA{mtcars}, 'mpg ~ wt + hp - hp') } qr/^vif: model contains fewer than 2 terms$/m,
	'a removal that leaves one term is refused';
{
	my %d = (%{ $DATA{mtcars} }, wt2 => [ map { 2 * $_ } @{ $DATA{mtcars}{wt} } ]);
	throws_ok { vif(\%d, 'mpg ~ wt + hp + wt2') }
		qr/^vif: there are aliased coefficients in the model \(wt2\)$/m,
		'an aliased column is refused, as car refuses it, by name';
}
throws_ok { vif($DATA{mtcars}, 'mpg ~ wt + hp + offset(disp)') } qr/^vif: offset\(\) is not supported$/m,
	'offset() is refused';
throws_ok { vif($DATA{mtcars}, { wt => 1 }) } qr/\Ausage: vif\(.*^vif: error: expected a formula string or an array ref of predictors\n\z/ms,
	'a hash of predictors is refused';
throws_ok { vif($DATA{mtcars}, undef) } qr/\Ausage: vif\(.*^vif: error: expected a formula string or an array ref of predictors\n\z/ms,
	'an undef specification is refused';
throws_ok { vif($DATA{mtcars}, 'wt + hp') } qr/\Ausage: vif\(.*^vif: error: expected a formula string or an array ref of predictors\n\z/ms,
	'a string with no ~ is refused';
throws_ok { vif(42, 'mpg ~ wt + hp') } qr/\Ausage: vif\(.*^vif: error: first argument must be a data reference\n\z/ms,
	'data that is not a reference is refused';
# through 0.3217 the response was ignored, so one that was not there worked
throws_ok { vif($DATA{mtcars}, 'y ~ wt + hp') }
	qr/^vif: the response 'y' is not a column of the data; leave it out, as in '~ x1 \+ x2', to use every row the predictors have$/m,
	'a response the data do not have is named';
throws_ok { vif({ y => [1, 2, 3], a => [1, undef, 3], b => [undef, 2, 3] }, 'y ~ a + b') }
	qr/^vif: fewer than two complete rows$/m, 'one complete row is refused';
throws_ok { vif({ y => [1, 2, 3, 4], a => [1, 2, 9**9**9, 4], b => [4, 1, 3, 2] }, 'y ~ a + b') }
	qr/^vif: NA\/NaN\/Inf in 'x' \(row '3'\)$/m, 'an infinite predictor is refused, as lm() refuses it';
throws_ok { vif({ y => [1, 2, -9**9**9, 4], a => [1, 2, 3, 4], b => [4, 1, 3, 2] }, 'y ~ a + b') }
	qr/^vif: NA\/NaN\/Inf in 'y' \(row '3'\)$/m, 'an infinite response is refused, as lm() refuses it';

# Devel::Cover's own per-line counters are allocated inside whatever block is
# running and are reported as leaks, so the check is skipped under it.
no_leaks_ok {
	local $SIG{__WARN__} = sub {};
	vif($DATA{mtcars}, 'mpg ~ wt*hp + disp');
	vif($DATA{warpbreaks}, 'breaks ~ wool * tension');
	vif($DATA{Duncan}, [qw(income education type)]);
	eval { vif($DATA{mtcars}, 'mpg ~ wt') };
	eval { vif({ y => [1, 2, 3, 4], a => [1, 2, 9**9**9, 4], b => [4, 1, 3, 2] }, 'y ~ a + b') };
} 'vif does not leak' unless $INC{'Devel/Cover.pm'};

done_testing();
