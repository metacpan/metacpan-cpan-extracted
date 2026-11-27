#!/usr/bin/env perl
# age_standardize(), against the Fay-Feuer directly standardized rate in R.
#
# Provenance:
#   There is no reference suite to take cases from: base R, the packages in
#   ~/Scripts/r-pkg-sources, SciPy, statsmodels and pandas have no direct
#   age standardization, and epitools (the README's reference,
#   ageadjust.direct) is not installed.  The expected values are therefore the
#   Fay-Feuer (1997, Stat Med 16:791-801) formulas written out in base R with
#   qgamma, R 4.6.2, in t/age_standardize.R.fayfeuer.R, which also records
#   that this transcription was not checked against epitools' own source.  The
#   "readme" and "per1e5" rows reproduce the numbers printed in README.md
#   (1097.8, 1569.6, 114.4 per 100k).  The remaining rows vary conf_level,
#   per, zero cells, a single stratum, and non-integer weights and populations.
# Re-run:  Rscript t/age_standardize.R.fayfeuer.R
# This test never runs R.
#
# Tolerance: 1e-9 relative.  The CI limits are a gamma quantile found by
# iteration in both R and the module; on this (double) build they agreed to
# the digits printed, so 1e-9 leaves headroom for long double and quadmath
# builds, whose bisection stops elsewhere.
#
# Deliberate differences: none known.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # throws_ok / lives_and
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

sub near {
	my ($got, $want, $tol, $name) = @_;
	my $scale = abs($want) > 0 ? abs($want) : 1;
	my $ok = defined $got && abs($got - $want) <= $tol * $scale;
	ok($ok, $name) or diag("got " . (defined $got ? $got : 'undef') . ", expected $want");
}

# [name, count, pop, stdpop, conf_level, per, crude, adj, lower, upper, se]
my @CASES = (
	[ 'readme', [5, 20, 55, 60], [1000, 3000, 4000, 2000], [2000, 3000, 3000, 2000], 0.95, 1, 0.014, 0.013125000000000001, 0.010978185249693982, 0.015696091617338891, 0.0011442792491345808 ],
	[ 'per1e5', [5, 20, 55, 60], [1000, 3000, 4000, 2000], [2000, 3000, 3000, 2000], 0.95, 1e+05, 1400, 1312.5000000000002, 1097.8185249693981, 1569.6091617338891, 114.42792491345809 ],
	[ 'cl90', [5, 20, 55, 60], [1000, 3000, 4000, 2000], [2000, 3000, 3000, 2000], 0.9, 1, 0.014, 0.013125000000000001, 0.011301226512129557, 0.015291521190408452, 0.0011442792491345808 ],
	[ 'cl99', [5, 20, 55, 60], [1000, 3000, 4000, 2000], [2000, 3000, 3000, 2000], 0.99, 1, 0.014, 0.013125000000000001, 0.010364982108213804, 0.016506980958638447, 0.0011442792491345808 ],
	[ 'cl50', [5, 20, 55, 60], [1000, 3000, 4000, 2000], [2000, 3000, 3000, 2000], 0.5, 1, 0.014, 0.013125000000000001, 0.012336148209585271, 0.014089034654144333, 0.0011442792491345808 ],
	[ 'zerocell', [0, 2, 15, 40, 90], [5000, 8000, 9000, 6000, 3000], [1, 2, 3, 2, 1], 0.95, 1, 0.0047419354838709677, 0.0054259259259259261, 0.0045839232455118818, 0.0063779111179082136, 0.00044771175569394752 ],
	[ 'rare', [0, 0, 1, 2], [1e+05, 90000, 80000, 50000], [30, 30, 25, 15], 0.95, 1e+05, 0.93749999999999989, 0.91249999999999998, 0.18810244094595741, 2.7322789494616351, 0.52693097270894984 ],
	[ 'single', [12], [400], [1], 0.95, 1, 0.029999999999999999, 0.029999999999999999, 0.015501437771805543, 0.052403962620442383, 0.0086602540378443865 ],
	[ 'big', [120, 540, 2310, 5800, 9000], [1e+05, 2e+05, 3e+05, 250000, 1e+05], [0.2, 0.3, 0.25, 0.15, 0.1], 0.999, 1, 0.018705263157894735, 0.015454999999999998, 0.015063359743491251, 0.015854794548833522, 0.00011994651585880545 ],
	[ 'equalwt', [3, 7, 11], [100, 100, 100], [1, 1, 1], 0.95, 1, 0.070000000000000007, 0.070000000000000007, 0.043331103280253962, 0.10700243578314465, 0.015275252316519466 ],
	);

for my $c (@CASES) {
	my ($name, $count, $pop, $std, $cl, $per, $crude, $adj, $lo, $hi, $se) = @$c;
	my $r = eval { age_standardize($count, $pop, $std, conf_level => $cl, per => $per) };
	if (!$r) { fail("$name: died: $@") for 1 .. 7; next }
	near($r->{crude_rate},   $crude, 1e-9, "$name: crude_rate");
	near($r->{adj_rate},     $adj,   1e-9, "$name: adj_rate");
	near($r->{conf_int}[0],  $lo,    1e-9, "$name: conf_int lower");
	near($r->{conf_int}[1],  $hi,    1e-9, "$name: conf_int upper");
	near($r->{se},           $se,    1e-9, "$name: se");
	near($r->{conf_level},   $cl,    1e-12, "$name: conf_level echoed");
	near($r->{per},          $per,   1e-12, "$name: per echoed");

	# the named form and the rate form give the same adjusted rate
	my $n = eval { age_standardize(count => $count, pop => $pop, stdpop => $std,
		conf_level => $cl, per => $per) };
	near($n ? $n->{adj_rate} : undef, $adj, 1e-9, "$name: named form");
	my @rate = map { $count->[$_] / $pop->[$_] } 0 .. $#$count;
	my $q = eval { age_standardize(rate => \@rate, pop => $pop, stdpop => $std,
		conf_level => $cl, per => $per) };
	near($q ? $q->{adj_rate} : undef, $adj, 1e-9, "$name: rate form");
}

# count and rate are alternatives
throws_ok { age_standardize(pop => [1, 2], stdpop => [1, 1]) } qr/count.*or.*rate/, 'neither count nor rate dies';

my @c = (5, 20, 55, 60); my @p = (1000, 3000, 4000, 2000); my @s = (2000, 3000, 3000, 2000);
no_leaks_ok { age_standardize(\@c, \@p, \@s, per => 100_000, conf_level => 0.9) }
	'age_standardize does not leak' unless $INC{'Devel/Cover.pm'};

done_testing();
