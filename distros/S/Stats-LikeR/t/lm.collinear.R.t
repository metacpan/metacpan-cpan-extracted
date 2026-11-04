#!/usr/bin/env perl
#
# lm() and glm() on ill-conditioned and collinear designs: which columns are
# aliased, and how many digits survive in the rest.
#
# Expected values: R 4.6.1 stats::lm(), glm() and their summaries, printed at
# full precision by t/lm.collinear.R.R, which also says how to re-run it.  The
# test never runs R.  Cases:
#
#   longley_lm, longley_glm
#       R's longley data, lm(Employed ~ ., data = longley), from R's
#       tests/reg-tests-1b.R line 205, whose own check is that
#       kappa(fit, exact = TRUE) is 23845862.  Through 0.3413 lm() and glm()
#       solved the normal equations, which square that condition number, and
#       GNP.deflator and Population came out 2.7e-8 from R.
#   pr2776_lm, pr2776_glm
#       R's tests/reg-tests-2.R line 885, "wishlist PR#2776: aliased coefs in
#       lm/glm": x2 is x1, so x2 is aliased and x3 is not.  y is R's
#       set.seed(123); x1 + rnorm(10), frozen below.
#   against_r, shifted_lm, shifted_glm, shifted_poisson
#       SciPy 1.18.0 scipy/stats/tests/test_stats.py,
#       TestRegression.test_regress_against_R, whose expected values are
#       themselves R's lm(y ~ x).  `shifted` adds 1e7 to x, which leaves the
#       slope alone and puts x's spread at 1.9e-6 of its norm: lm.fit() keeps a
#       column down to 1e-7 of it, and through 0.3413 lm() and glm() aliased
#       anything under 1e-5, so all three shifted fits came back with x NaN.
#       Exact rational least squares on these doubles gives the slope
#       0.6746104491292392; R's 0.6746104491267652 is 3.7e-12 from it, and
#       lm()'s is closer.
#   big_on_x, x_on_big, x_on_little, x_on_big_little
#       Wilkinson's NASTY data, as SciPy's TestRegression carries them.
#       big_on_x is test_linregressBIGX (W.II.F): an exact line, intercept
#       99999990 and slope 1, whose standard errors SciPy checks to atol 1e-7.
#       In the other three, BIG and LITTLE each vary by 2.6e-8 of their norm,
#       under lm.fit()'s 1e-7, so R aliases every one of them, and W.IV.C's
#       BIG + LITTLE leaves the intercept alone.
#
# On tolerances: a backward-stable least-squares solver may be wrong by about
# epsilon * kappa, which is 5.3e-9 relative for longley, the worst of these
# designs.  The worst disagreements with R measured on the double perl on
# 2026-11-03 were 1.0e-11 for the least-squares fits (shifted_glm's standard
# errors; longley's worst was 3.0e-12) and 8.3e-11 for shifted_poisson's
# deviance, where both IRLS loops stop at epsilon = 1e-8 rather than at the
# MLE.  1e-9 is twelve times the worst of those, and long-double and quadmath
# builds land nearer the exact answer, so no closer to R than R is to it; it
# still fails 0.3413's 2.7e-8 on longley.  The ranks, the
# residual degrees of freedom and which columns are aliased are compared
# exactly.  big_on_x's standard errors are rounding noise in R (5.8e-16 and
# 1.0e-16, against an exact 0) and are held to SciPy's atol 1e-7, as its
# residual sum of squares is to 1e-10.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR qw(lm glm);
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

my $RTOL = 1e-9;	# see "On tolerances" above

my %LONGLEY = (
	GNP_deflator => [83, 88.5, 88.2, 89.5, 96.2, 98.1, 99, 100, 101.2, 104.6, 108.4, 110.8, 112.6, 114.2, 115.7, 116.9],
	GNP => [234.289, 259.426, 258.054, 284.599, 328.975, 346.999, 365.385, 363.112, 397.469, 419.18, 442.769, 444.546, 482.704, 502.601, 518.173, 554.894],
	Unemployed => [235.6, 232.5, 368.2, 335.1, 209.9, 193.2, 187, 357.8, 290.4, 282.2, 293.6, 468.1, 381.3, 393.1, 480.6, 400.7],
	Armed_Forces => [159, 145.6, 161.6, 165, 309.9, 359.4, 354.7, 335, 304.8, 285.7, 279.8, 263.7, 255.2, 251.4, 257.2, 282.7],
	Population => [107.608, 108.632, 109.773, 110.929, 112.075, 113.27, 115.094, 116.219, 117.388, 118.734, 120.445, 121.95, 123.366, 125.368, 127.852, 130.081],
	Year => [1947, 1948, 1949, 1950, 1951, 1952, 1953, 1954, 1955, 1956, 1957, 1958, 1959, 1960, 1961, 1962],
	Employed => [60.323, 61.122, 60.171, 61.187, 63.221, 63.639, 64.989, 63.761, 66.019, 67.857, 68.169, 66.513, 68.655, 69.564, 69.331, 70.551],
);

my @PR2776_Y = @{ [0.4395243534477874, 1.76982251051672, 4.558708314149124, 4.070508391424576, 5.129287735160946, 7.715064986883281, 7.460916205989203, 6.734938765393466, 8.313147148106474, 9.554338029900041] };

my %EXPECT = (
	longley_lm => {
		names    => ['Intercept', 'GNP_deflator', 'GNP', 'Unemployed', 'Armed_Forces', 'Population', 'Year'],
		estimate => [-3482.258634595815, 0.015061872271372779, -0.035819179292591, -0.02020229803816824, -0.010332268671735891, -0.051104105653579195, 1.8291514646135503],
		se       => [890.4203836073757, 0.08491492577476738, 0.03349100777224341, 0.004883996816517028, 0.0021427416316167573, 0.22607320006937262, 0.45547849914221344],
		rank => 7, df => 9,
		rss => 0.8364240555059197,
	},
	longley_glm => {
		names    => ['Intercept', 'GNP_deflator', 'GNP', 'Unemployed', 'Armed_Forces', 'Population', 'Year'],
		estimate => [-3482.258634595815, 0.015061872271372779, -0.035819179292591, -0.02020229803816824, -0.010332268671735891, -0.051104105653579195, 1.8291514646135503],
		se       => [890.4203836071396, 0.08491492577474487, 0.03349100777223453, 0.004883996816515734, 0.002142741631616189, 0.22607320006931267, 0.4554784991420927],
		rank => 7, df => 9,
		deviance => 0.8364240555054762,
	},
	pr2776_lm => {
		names    => ['Intercept', 'x1', 'x2', 'x3'],
		estimate => [-0.9025508178830123, 1.6320378680812155, undef, -0.6490991720692235],
		se       => [1.0338267779588015, 0.43176964713756677, undef, 0.3825316684741734],
		rank => 3, df => 7,
		rss => 5.4083744441730595,
	},
	pr2776_glm => {
		names    => ['Intercept', 'x1', 'x2', 'x3'],
		estimate => [-0.9025508178830123, 1.6320378680812155, undef, -0.6490991720692235],
		se       => [1.0338267779588013, 0.43176964713756666, undef, 0.38253166847417336],
		rank => 3, df => 7,
		deviance => 5.408374444173058,
	},
	against_r => {
		names    => ['Intercept', 'x'],
		estimate => [-38.455087076077, 0.6746104491292394],
		se       => [8.04901330299271, 0.05190514247310441],
		rank => 2, df => 8,
		rss => 84.65215398716776,
	},
	shifted_lm => {
		names    => ['Intercept', 'x'],
		estimate => [-6746142.946354725, 0.6746104491267652],
		se       => [519059.4077293613, 0.05190514247174299],
		rank => 2, df => 8,
		rss => 84.65215398352073,
	},
	shifted_glm => {
		names    => ['Intercept', 'x'],
		estimate => [-6746142.946354725, 0.6746104491267652],
		se       => [519059.40772895113, 0.05190514247170198],
		rank => 2, df => 8,
		deviance => 84.65215398338695,
	},
	shifted_poisson => {
		names    => ['Intercept', 'x'],
		estimate => [-101685.38913687215, 0.010168798361190725],
		se       => [19533.345101020393, 0.001953303675718697],
		rank => 2, df => 8,
		deviance => 1.2804232892528313,
	},
	big_on_x => {
		names    => ['Intercept', 'X'],
		estimate => [99999990, 0.9999999999999998],
		se       => [5.784129533689426e-16, 1.0278667914282462e-16],
		rank => 2, df => 7,
		rss => 4.4373425918681914e-30,
	},
	x_on_big => {
		names    => ['Intercept', 'BIG'],
		estimate => [5, undef],
		se       => [0.9128709291752768, undef],
		rank => 1, df => 8,
		rss => 60,
	},
	x_on_little => {
		names    => ['Intercept', 'LITTLE'],
		estimate => [5, undef],
		se       => [0.9128709291752768, undef],
		rank => 1, df => 8,
		rss => 60,
	},
	x_on_big_little => {
		names    => ['Intercept', 'BIG', 'LITTLE'],
		estimate => [5, undef, undef],
		se       => [0.9128709291752768, undef, undef],
		rank => 1, df => 8,
		rss => 60,
	},
);

sub is_nanish {
	my ($x) = @_;
	return 1 if !defined $x;
	no warnings 'numeric';
	return $x != $x ? 1 : 0;
}

my ($worst, $worst_at) = (0, '');
sub near {
	my ($got, $want, $name) = @_;
	if (!defined $want) { return ok(is_nanish($got), "$name is NaN (aliased)") }
	if (is_nanish($got)) { return ok(0, "$name: got NaN, want $want") }
	my $rel = $want == 0 ? abs($got) : abs($got - $want) / abs($want);
	($worst, $worst_at) = ($rel, $name) if $rel > $worst;
	ok($rel <= $RTOL, $name) or diag(sprintf "got %.17g, want %.17g, rel %.3g", $got, $want, $rel);
}

my $SHIFT_X = [map { $_ + 1e7 } 151, 174, 138, 186, 128, 136, 179, 163, 152, 131];
my $SY      = [63, 81, 56, 91, 47, 57, 76, 72, 62, 48];
my @X       = 1 .. 9;
my %NASTY   = (
	X      => \@X,
	BIG    => [map { 99999990 + $_ } @X],
	LITTLE => [qw(0.99999991 0.99999992 0.99999993 0.99999994 0.99999995 0.99999996 0.99999997 0.99999998 0.99999999)],
);
my %PR = (y => \@PR2776_Y, x1 => [1 .. 10], x2 => [1 .. 10], x3 => [map { 0.1 * $_**2 } 1 .. 10]);

#case => [function, formula, data, family]
my %CASE = (
	longley_lm      => ['lm',  'Employed ~ .', \%LONGLEY],
	longley_glm     => ['glm', 'Employed ~ .', \%LONGLEY, 'gaussian'],
	pr2776_lm       => ['lm',  'y ~ x1 + x2 + x3', \%PR],
	pr2776_glm      => ['glm', 'y ~ x1 + x2 + x3', \%PR, 'gaussian'],
	against_r       => ['lm',  'y ~ x', { x => [151, 174, 138, 186, 128, 136, 179, 163, 152, 131], y => $SY }],
	shifted_lm      => ['lm',  'y ~ x', { x => $SHIFT_X, y => $SY }],
	shifted_glm     => ['glm', 'y ~ x', { x => $SHIFT_X, y => $SY }, 'gaussian'],
	shifted_poisson => ['glm', 'y ~ x', { x => $SHIFT_X, y => $SY }, 'poisson'],
	big_on_x        => ['lm',  'BIG ~ X', \%NASTY],
	x_on_big        => ['lm',  'X ~ BIG', \%NASTY],
	x_on_little     => ['lm',  'X ~ LITTLE', \%NASTY],
	x_on_big_little => ['lm',  'X ~ BIG + LITTLE', \%NASTY],
);

for my $key (sort keys %CASE) {
	my ($fn, $f, $data, $family) = @{ $CASE{$key} };
	my $e = $EXPECT{$key};
	my $r = $fn eq 'lm' ? lm(formula => $f, data => $data)
	                    : glm(formula => $f, data => $data, family => $family);
	is($r->{rank}, $e->{rank}, "$key: rank $e->{rank}");
	is($r->{df_residual}, $e->{df}, "$key: residual df $e->{df}");
	is_deeply([sort keys %{ $r->{coefficients} }], [sort @{ $e->{names} }], "$key: coefficient names");
	for my $j (0 .. $#{ $e->{names} }) {
		my $n = $e->{names}[$j];
		near($r->{coefficients}{$n}, $e->{estimate}[$j], "$key: $n estimate");
		my $se = $r->{summary}{$n}{'Std. Error'};
		if ($key eq 'big_on_x') {
			ok(abs($se) < 1e-7, "$key: $n std. error is 0 to SciPy's atol 1e-7") or diag("got $se");
		} else {
			near($se, $e->{se}[$j], "$key: $n std. error");
		}
	}
	if (exists $e->{rss}) {
		if ($key eq 'big_on_x') { ok($r->{rss} < 1e-10, "$key: rss is 0 to 1e-10") or diag("got $r->{rss}") }
		else                    { near($r->{rss}, $e->{rss}, "$key: rss") }
	} else {
		near($r->{deviance}, $e->{deviance}, "$key: deviance");
	}
}
diag(sprintf 'worst relative disagreement with R: %.3g (%s)', $worst, $worst_at);

no_leaks_ok { lm(formula => 'y ~ x1 + x2 + x3', data => \%PR) } 'no leak in an aliased lm() fit';
no_leaks_ok { glm(formula => 'y ~ x1 + x2 + x3', data => \%PR) } 'no leak in an aliased glm() fit';

done_testing();
