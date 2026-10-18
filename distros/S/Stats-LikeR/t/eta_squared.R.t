#!/usr/bin/env perl
# eta_squared() against R 4.6.1's one-way ANOVA tables.
#
# PROVENANCE
#
# t/eta_squared.R.R, committed beside this file, generated every literal in
# %DATA, @R_ROWS and %WARPBREAKS under R 4.6.1 (2026-06-24) at
# options(digits = 17).  Re-run it with
#     Rscript t/eta_squared.R.R
# This test never invokes R; it reads the frozen literals.
#
# The data are R's own, from the datasets package, each the subject of a
# documented example: airquality's Ozone ~ Month (?kruskal.test), PlantGrowth's
# weight ~ group (?PlantGrowth), InsectSprays' count ~ spray (?InsectSprays),
# chickwts' weight ~ feed (?chickwts), and warpbreaks' breaks ~ wool + tension
# (?warpbreaks) for a two-factor table.  R has no eta_squared(), so the
# expected values are summary(aov(y ~ factor(g)))'s sums of squares put through
# the definitions in README.md:
#
#   eta_sq   = SS_effect / (SS_effect + SS_resid)
#   omega_sq = (SS_effect - Df_effect * MS_resid) / (SS_effect + SS_resid + MS_resid)
#
# WHAT IT PINS
#
# Group codes are a factor whatever they look like.  Up to 0.3217 the raw form
# passed a formula to aov(), which fits a column of numbers as one slope: the
# airquality example, whose Month is 5 to 9, gave eta_sq 0.0271 on 1 df for
# R's 0.2352 on 4.  Each set is run with its own labels, with its labels
# replaced by numeric codes, and as the result of an aov() whose formula column
# is a factor, and all three must agree with R.
#
# A two-factor aov() result is refused.  Up to 0.3217 it was answered for the
# term whose name sorted first, with SS_total taken as that term's SS plus the
# residual SS -- partial eta-squared, reported as eta_sq.
#
# TOLERANCE
#
# 1e-12 relative.  The worst disagreement observed on the double build is
# 2.7e-15, PlantGrowth's omega_sq through the aov() form: a few ulp, the
# difference between R's QR and aov()'s Givens rotations in summing the same
# squares.  The diag() below the loop reports it on every run.  Across the
# nine perls of ./test.all.perls.pl on 2026-10-16 no build was worse; the
# long-double and quadmath perls, which read the decimal data as slightly
# different numbers, were at 7.4e-16.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Test::LeakTrace 'no_leaks_ok';
use Stats::LikeR qw(eta_squared aov);

my $TOL = 1e-12;

sub rel_ok {
	my ($got, $want, $name) = @_;
	ok(abs($got - $want) <= $TOL * abs($want), $name)
		or diag(sprintf "  got %.17g\n  want %.17g", $got, $want);
	return abs($got - $want) / abs($want);
}

my %DATA = (
	airquality => {
		y => [ 41, 36, 12, 18, undef, 28, 23, 19, 8, undef, 7, 16, 11, 14, 18, 14, 34, 6, 30, 11, 1, 11, 4, 32, undef, undef, undef, 23, 45, 115, 37, undef, undef, undef, undef, undef, undef, 29, undef, 71, 39, undef, undef, 23, undef, undef, 21, 37, 20, 12, 13, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, 135, 49, 32, undef, 64, 40, 77, 97, 97, 85, undef, 10, 27, undef, 7, 48, 35, 61, 79, 63, 16, undef, undef, 80, 108, 20, 52, 82, 50, 64, 59, 39, 9, 16, 78, 35, 66, 122, 89, 110, undef, undef, 44, 28, 65, undef, 22, 59, 23, 31, 44, 21, 9, undef, 45, 168, 73, undef, 76, 118, 84, 85, 96, 78, 73, 91, 47, 32, 20, 23, 21, 24, 44, 21, 28, 9, 13, 46, 18, 13, 24, 16, 13, 23, 36, 7, 14, 30, undef, 14, 18, 20 ],
		g => [ 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9 ],
	},
	PlantGrowth => {
		y => [ 4.1699999999999999, 5.5800000000000001, 5.1799999999999997, 6.1100000000000003, 4.5, 4.6100000000000003, 5.1699999999999999, 4.5300000000000002, 5.3300000000000001, 5.1399999999999997, 4.8099999999999996, 4.1699999999999999, 4.4100000000000001, 3.5899999999999999, 5.8700000000000001, 3.8300000000000001, 6.0300000000000002, 4.8899999999999997, 4.3200000000000003, 4.6900000000000004, 6.3099999999999996, 5.1200000000000001, 5.54, 5.5, 5.3700000000000001, 5.29, 4.9199999999999999, 6.1500000000000004, 5.7999999999999998, 5.2599999999999998 ],
		g => [ 'ctrl', 'ctrl', 'ctrl', 'ctrl', 'ctrl', 'ctrl', 'ctrl', 'ctrl', 'ctrl', 'ctrl', 'trt1', 'trt1', 'trt1', 'trt1', 'trt1', 'trt1', 'trt1', 'trt1', 'trt1', 'trt1', 'trt2', 'trt2', 'trt2', 'trt2', 'trt2', 'trt2', 'trt2', 'trt2', 'trt2', 'trt2' ],
	},
	InsectSprays => {
		y => [ 10, 7, 20, 14, 14, 12, 10, 23, 17, 20, 14, 13, 11, 17, 21, 11, 16, 14, 17, 17, 19, 21, 7, 13, 0, 1, 7, 2, 3, 1, 2, 1, 3, 0, 1, 4, 3, 5, 12, 6, 4, 3, 5, 5, 5, 5, 2, 4, 3, 5, 3, 5, 3, 6, 1, 1, 3, 2, 6, 4, 11, 9, 15, 22, 15, 16, 13, 10, 26, 26, 24, 13 ],
		g => [ 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'C', 'C', 'C', 'C', 'C', 'C', 'C', 'C', 'C', 'C', 'C', 'C', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'E', 'E', 'E', 'E', 'E', 'E', 'E', 'E', 'E', 'E', 'E', 'E', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F' ],
	},
	chickwts => {
		y => [ 179, 160, 136, 227, 217, 168, 108, 124, 143, 140, 309, 229, 181, 141, 260, 203, 148, 169, 213, 257, 244, 271, 243, 230, 248, 327, 329, 250, 193, 271, 316, 267, 199, 171, 158, 248, 423, 340, 392, 339, 341, 226, 320, 295, 334, 322, 297, 318, 325, 257, 303, 315, 380, 153, 263, 242, 206, 344, 258, 368, 390, 379, 260, 404, 318, 352, 359, 216, 222, 283, 332 ],
		g => [ 'horsebean', 'horsebean', 'horsebean', 'horsebean', 'horsebean', 'horsebean', 'horsebean', 'horsebean', 'horsebean', 'horsebean', 'linseed', 'linseed', 'linseed', 'linseed', 'linseed', 'linseed', 'linseed', 'linseed', 'linseed', 'linseed', 'linseed', 'linseed', 'soybean', 'soybean', 'soybean', 'soybean', 'soybean', 'soybean', 'soybean', 'soybean', 'soybean', 'soybean', 'soybean', 'soybean', 'soybean', 'soybean', 'sunflower', 'sunflower', 'sunflower', 'sunflower', 'sunflower', 'sunflower', 'sunflower', 'sunflower', 'sunflower', 'sunflower', 'sunflower', 'sunflower', 'meatmeal', 'meatmeal', 'meatmeal', 'meatmeal', 'meatmeal', 'meatmeal', 'meatmeal', 'meatmeal', 'meatmeal', 'meatmeal', 'meatmeal', 'casein', 'casein', 'casein', 'casein', 'casein', 'casein', 'casein', 'casein', 'casein', 'casein', 'casein', 'casein' ],
	},
);

# [ set, Df_effect, SS_effect, SS_resid, MS_resid, eta_sq, omega_sq ]
my @R_ROWS = (
	[ 'airquality', 4, 29437.896478043058, 95705.163866784569, 862.20868348454565, 0.23523395062361344, 0.20625376973930656 ],
	[ 'PlantGrowth', 2, 3.7663399999999987, 10.492089999999997, 0.38859592592592584, 0.26414829683211966, 0.20407884598997089 ],
	[ 'InsectSprays', 5, 2668.8333333333358, 1015.1666666666681, 15.381313131313153, 0.724439015562794, 0.70063790355335143 ],
	[ 'chickwts', 5, 231129.16210292038, 195556.0209956709, 3008.5541691641679, 0.54168546567391562, 0.50288466532257003 ],
);

my ($worst, $worst_at) = (0, '');
for my $r (@R_ROWS) {
	my ($set, $df, $ss_eff, $ss_res, $ms_res, $eta, $omega) = @$r;
	my ($y, $g) = @{ $DATA{$set} }{qw(y g)};
	# the same groups under numeric codes, 1 for the first label seen
	my (%code, @num);
	push @num, $code{$_} ||= 1 + keys %code for @$g;
	# aov() with a formula fits a numeric column as a slope, as R's aov() does
	# with airquality's Month unless it is wrapped in factor(); a letter in
	# front of every label is this module's factor()
	my @lab = map { "L$_" } @$g;
	my %form = (
		labels  => eta_squared($y, $g),
		codes   => eta_squared($y, \@num),
		aov     => eta_squared(aov({ y => $y, g => \@lab }, 'y ~ g')),
	);
	for my $f (sort keys %form) {
		my $e = $form{$f};
		for ([ eta_sq => $eta ], [ partial_eta_sq => $eta ], [ omega_sq => $omega ]) {
			my ($k, $want) = @$_;
			my $err = rel_ok($e->{$k}, $want, "$set, $f: $k");
			($worst, $worst_at) = ($err, "$set, $f, $k") if $err > $worst;
		}
	}
	is($form{labels}{term}, 'Group', "$set: the raw form's term is aov()'s stacked Group");
	is($form{aov}{term}, 'g', "$set: an aov() result's term is its own");
}
diag(sprintf 'worst relative error vs R: %.2g (%s)', $worst, $worst_at);

# The raw form takes oneway_test(var_equal => 1) where it can and aov()'s
# stacked form where oneway_test() would refuse the data; the loop above runs
# both, airquality (37 undef values) through aov() and the other three through
# oneway_test().  Each case oneway_test() refuses must still be aov()'s answer.
{
	my @cases = (
		[ 'one group',               [1, 2, 3],          [qw(a a a)] ],
		[ 'a group of one value',    [1, 2, 3, 4],       [qw(a b b b)] ],
		[ 'a non-numeric value',     [1, 'x', 3, 4, 5, 6], [qw(a a a b b b)] ],
		[ 'an undef value',          [1, undef, 3, 4, 5, 6], [qw(a a a b b b)] ],
	);
	for my $c (@cases) {
		my ($what, $v, $g) = @$c;
		my %by; push @{ $by{ $g->[$_] } }, $v->[$_] for 0 .. $#$v;
		my $want = do { local $SIG{__WARN__} = sub {}; eta_squared(aov(\%by)) };
		my $got  = do { local $SIG{__WARN__} = sub {}; eta_squared($v, $g) };
		is_deeply($got, $want, "$what: the raw form is aov()'s stacked answer");
	}
}

# An undef group drops its row, as an undef value does; airquality above has
# 37 undef values.
{
	my ($y, $g) = @{ $DATA{PlantGrowth} }{qw(y g)};
	my $all = eta_squared([ @$y[1 .. $#$y] ], [ @$g[1 .. $#$g] ]);
	my @g = @$g; $g[0] = undef;
	is_deeply(eta_squared($y, \@g), $all, 'an undef group drops its row');
}

my %WARPBREAKS = (
	breaks  => [ 26, 30, 54, 25, 70, 52, 51, 26, 67, 18, 21, 29, 17, 12, 18, 35, 30, 36, 36, 21, 24, 18, 10, 43, 28, 15, 26, 27, 14, 29, 19, 29, 31, 41, 20, 44, 42, 26, 19, 16, 39, 28, 21, 39, 29, 20, 21, 24, 17, 13, 15, 15, 16, 28 ],
	wool    => [ 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B' ],
	tension => [ 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H' ],
);
throws_ok { eta_squared(aov(\%WARPBREAKS, 'breaks ~ wool + tension')) }
	qr/^eta_squared: the aov\(\) result has 2 effect terms \(tension wool\); eta_squared\(\) measures a one-way design, which has one$/m,
	'a two-factor aov() result is refused';

throws_ok { eta_squared([1, 2, 3], [1, 2]) } qr/same length/, 'length mismatch';
throws_ok { eta_squared(42) } qr/expected an aov\(\) result/, 'neither form';
throws_ok { eta_squared({ a => 1 }) } qr/no Residuals term/, 'a hash that is not an ANOVA';

# Devel::Cover's own per-line counters are allocated inside whatever block is
# running and are reported as leaks, so the check is skipped under it.
no_leaks_ok {
	eta_squared(@{ $DATA{PlantGrowth} }{qw(y g)});
	eval { eta_squared(aov(\%WARPBREAKS, 'breaks ~ wool + tension')) };
} 'eta_squared does not leak' unless $INC{'Devel/Cover.pm'};

done_testing();
