#!/usr/bin/env perl

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Stats::LikeR;
use Test::LeakTrace;

# --- Test Case 1: Intercept-Free Modeling (R Compatibility) ---
my $data = {
 'y' => [2.0, 4.0, 6.0],
 'x' => [1.0, 2.0, 3.0]
};

my $res = glm(formula => 'y ~ x -1 ', data => $data, family => 'gaussian');
is($res->{'df.null'}, 3, 'Null degrees of freedom is valid_n when has_intercept is false');
# R null deviance with no intercept = sum(y^2) = 4 + 16 + 36 = 56
is($res->{'null.deviance'}, 56, 'Null deviance tracks R convention for intercept-free formulas');

no_leaks_ok {
	eval { glm(formula => 'y ~ x -1 ', data => $data, family => 'gaussian') }
} 'glm: no leaks with false intercept' unless $INC{'Devel/Cover.pm'};
# --- Test Case 2: Binomial Logistic Progression ---
$data = {
  success => [0.0, 0.0, 1.0, 1.0],
  predictor => [0.1, 0.2, 0.9, 0.8]
};

$res = glm(formula => 'success ~ predictor', data => $data, family => 'binomial');
ok($res->{converged}, 'Logistic model converged successfully via IRLS');
is($res->{family}, 'binomial', 'Family parameter tracked properly');

# --- Test Case 3: Car Names Mapping (Row Names) ---
my $mtcars = {
  'row.names' => ['Mazda RX4', 'Mazda RX4 Wag', 'Datsun 710'],
  'am'        => [1, 1, 1],
  'wt'        => [2.620, 2.875, 2.320],
  'hp'        => [110, 110, 93]
};
    
$res = glm(formula => 'am ~ wt + hp', data => $mtcars, family => 'gaussian');

ok(exists $res->{'deviance.resid'}{'Mazda RX4'}, 'Residual keys map to car names, not integers');
ok(exists $res->{'fitted.values'}{'Datsun 710'}, 'Fitted value keys map to car names, not integers');
#=c
# --- Test Case 4: Exception Handling & Leak Avoidance ---
my $invalid_binomial_data = {
  success => [-0.5, 2.0, 1.0, 0.0], # Breaks [0,1] domain rule
  predictor => [1, 2, 3, 4]
};

dies_ok {
  glm(formula => 'success ~ predictor', data => $invalid_binomial_data, family => 'binomial')
} 'Dies safely on binomial response outside [0,1] spectrum';

no_leaks_ok {
  eval { glm(formula => 'success ~ predictor', data => $invalid_binomial_data, family => 'binomial') };
} 'glm: No memory leaked when throwing an exception deep w/i XS execution' unless $INC{'Devel/Cover.pm'};

# ---------------------------------------------------------------------------
# Factor-bearing terms in the design matrix.
#
# glm() shares its design-matrix construction with lm(), and until that code
# handled factors component by component two kinds of model were wrong here: an
# interaction with a factor on either side died with a message about degrees of
# freedom, and a factor in a model with no intercept silently lost its first
# level, fitting one column where R fits one per level. Both are checked against
# R 4.6.1 glm() below, on R's own ToothGrowth and warpbreaks, gaussian and
# poisson respectively.
#
# The data are spelled out here rather than read from a file so the expected
# numbers cannot drift from the input. supp, wool and tension are character
# columns, so their levels are the sorted sets R derives from the same input --
# tension sorts H, L, M, which is why H is its reference level here rather than
# the L of R's own built-in factor.
{
	my $tooth = {
		len => [
		4.2, 11.5, 7.3, 5.8, 6.4, 10.0, 11.2, 11.2, 5.2, 7.0, 16.5, 16.5, 15.2,
		17.3, 22.5, 17.3, 13.6, 14.5, 18.8, 15.5, 23.6, 18.5, 33.9, 25.5, 26.4,
		32.5, 26.7, 21.5, 23.3, 29.5, 15.2, 21.5, 17.6, 9.7, 14.5, 10.0, 8.2,
		9.4, 16.5, 9.7, 19.7, 23.3, 23.6, 26.4, 20.0, 25.2, 25.8, 21.2, 14.5,
		27.3, 25.5, 26.4, 22.4, 24.5, 24.8, 30.9, 26.4, 27.3, 29.4, 23.0
		],
		supp => [
		'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC',
		'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC',
		'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ',
		'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ',
		'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ'
		],
		dose => [
		0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 1.0, 1.0, 1.0,
		1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
		2.0, 2.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 1.0,
		1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0,
		2.0, 2.0, 2.0, 2.0
		],
	};
	my $warp = {
		breaks => [
		26, 30, 54, 25, 70, 52, 51, 26, 67, 18, 21, 29, 17, 12, 18, 35, 30, 36,
		36, 21, 24, 18, 10, 43, 28, 15, 26, 27, 14, 29, 19, 29, 31, 41, 20, 44,
		42, 26, 19, 16, 39, 28, 21, 39, 29, 20, 21, 24, 17, 13, 15, 15, 16, 28
		],
		wool => [
		'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A',
		'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'B',
		'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B',
		'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B'
		],
		tension => [
		'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'M', 'M', 'M', 'M', 'M',
		'M', 'M', 'M', 'M', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'L',
		'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'M', 'M', 'M', 'M', 'M', 'M',
		'M', 'M', 'M', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H'
		],
	};

	# --- gaussian, numeric x factor interaction -------------------------------
	# R: glm(len ~ dose * supp, ToothGrowth, family = gaussian)
	my $gi = glm(formula => 'len ~ dose * supp', data => $tooth, family => 'gaussian');
	is_deeply([ sort @{ $gi->{terms} } ],
		[ sort qw(Intercept dose suppVC dose:suppVC) ],
		'glm: a numeric x factor interaction expands as R does');
	is($gi->{'df.residual'}, 56, 'glm: interaction df.residual matches R');
	my %gi_want = (
		Intercept     => [ 11.549999999999999,   1.5813942722761327 ],
		dose          => [  7.8114285714285723,  1.1954217054813172 ],
		suppVC        => [ -8.2550000000000097,  2.236429227312037  ],
		'dose:suppVC' => [  3.9042857142857188,  1.6905815886468536 ],
	);
	for my $t (sort keys %gi_want) {
		my ($est, $se) = @{ $gi_want{$t} };
		cmp_ok(abs($gi->{coefficients}{$t} - $est), '<', 1e-9 * abs($est),
			"glm: interaction coefficient $t matches R");
		cmp_ok(abs($gi->{summary}{$t}{'Std. Error'} - $se), '<', 1e-9 * abs($se),
			"glm: interaction Std. Error for $t matches R");
	}
	cmp_ok(abs($gi->{deviance} - 933.63492857142842), '<', 1e-9 * 933.63492857142842,
		'glm: interaction deviance matches R');

	# --- gaussian, factor with no intercept -----------------------------------
	# R: glm(len ~ supp - 1, ...) keeps both levels, each coefficient being that
	# group's own mean.
	my $gn = glm(formula => 'len ~ supp - 1', data => $tooth, family => 'gaussian');
	is_deeply([ sort @{ $gn->{terms} } ], [qw(suppOJ suppVC)],
		'glm: a factor with no intercept keeps every level, as R does');
	is($gn->{'df.residual'}, 58, 'glm: no-intercept factor df.residual matches R');
	cmp_ok(abs($gn->{coefficients}{suppOJ} - 20.663333333333334), '<', 1e-9,
		'glm: suppOJ is the OJ group mean');
	cmp_ok(abs($gn->{coefficients}{suppVC} - 16.963333333333306), '<', 1e-9,
		'glm: suppVC is the VC group mean');
	cmp_ok(abs($gn->{deviance} - 3246.8593333333333), '<', 1e-9 * 3246.8593333333333,
		'glm: no-intercept factor deviance matches R');

	# --- poisson, factor x factor interaction ---------------------------------
	# R: glm(breaks ~ wool * tension, warpbreaks, family = poisson)
	my $pi = glm(formula => 'breaks ~ wool * tension', data => $warp, family => 'poisson');
	is_deeply([ sort @{ $pi->{terms} } ],
		[ sort qw(Intercept woolB tensionL tensionM woolB:tensionL woolB:tensionM) ],
		'glm: a factor x factor interaction expands as R does');
	is($pi->{'df.residual'}, 48, 'glm: poisson interaction df.residual matches R');
	my %pi_want = (
		Intercept        => [  3.2009381241905026,    0.067267136953331322 ],
		woolB            => [ -0.26826398660364542,   0.10218623673839214  ],
		tensionL         => [  0.59579872578642523,   0.083777229927664343 ],
		tensionM         => [ -0.022884293841625412,  0.095679104431298706 ],
		'woolB:tensionL' => [ -0.18836317369040623,   0.12989529333490726  ],
		'woolB:tensionM' => [  0.44981364061829127,   0.13759597261206266  ],
	);
	# Standard errors are held to the same bound as the coefficients. They come
	# from the information matrix of the penultimate IRLS iterate, which is the
	# matrix R reports from as well, so the two agree to about 1e-14 here. They
	# used to sit 2e-6 away, because a step-halving guard that treated any rise in
	# deviance as divergence made glm() take three more iterations than R and so
	# reach a different penultimate iterate; see the note in LikeR.xs.
	for my $t (sort keys %pi_want) {
		my ($est, $se) = @{ $pi_want{$t} };
		cmp_ok(abs($pi->{coefficients}{$t} - $est), '<', 1e-9 * abs($est),
			"glm: poisson interaction coefficient $t matches R");
		cmp_ok(abs($pi->{summary}{$t}{'Std. Error'} - $se), '<', 1e-9 * abs($se),
			"glm: poisson interaction Std. Error for $t matches R");
	}
	cmp_ok(abs($pi->{deviance} - 182.30513128584673), '<', 1e-8 * 182.30513128584673,
		'glm: poisson interaction deviance matches R');

	# --- poisson, two factors and no intercept --------------------------------
	# Only the first factor can take the empty margin, so wool is coded in full
	# and tension falls back to contrasts. Coding both in full would be rank
	# deficient.
	my $pn = glm(formula => 'breaks ~ wool + tension - 1', data => $warp, family => 'poisson');
	is_deeply([ sort @{ $pn->{terms} } ], [qw(tensionL tensionM woolA woolB)],
		'glm: with no intercept only the first factor is coded in full');
	is($pn->{'df.residual'}, 50, 'glm: no-intercept poisson df.residual matches R');
	my %pn_want = (
		woolA    => [ 3.1734746484364513,  0.05567331237245942  ],
		woolB    => [ 2.9674862057875893,  0.058073053866257801 ],
		tensionL => [ 0.51848849651734441, 0.063959443312719785 ],
		tensionM => [ 0.19716806491715241, 0.068332668548601219 ],
	);
	for my $t (sort keys %pn_want) {
		my ($est, $se) = @{ $pn_want{$t} };
		cmp_ok(abs($pn->{coefficients}{$t} - $est), '<', 1e-9 * abs($est),
			"glm: no-intercept poisson coefficient $t matches R");
		cmp_ok(abs($pn->{summary}{$t}{'Std. Error'} - $se), '<', 1e-9 * abs($se),
			"glm: no-intercept poisson Std. Error for $t matches R");
	}

	# Crossing is associative, so a * b has to reach the same columns as writing
	# the main effects and the interaction out longhand.
	is_deeply([ sort @{ $pi->{terms} } ],
		[ sort @{ glm(formula => 'breaks ~ wool + tension + wool:tension',
			data => $warp, family => 'poisson')->{terms} } ],
		'glm: a * b expands to the same columns as a + b + a:b');

	no_leaks_ok {
		glm(formula => 'len ~ dose * supp', data => $tooth, family => 'gaussian');
	} 'glm: no leak fitting a factor-bearing interaction' unless $INC{'Devel/Cover.pm'};
	no_leaks_ok {
		glm(formula => 'len ~ supp - 1', data => $tooth, family => 'gaussian');
	} 'glm: no leak fitting a full-coded factor' unless $INC{'Devel/Cover.pm'};
}

# ---------------------------------------------------------------------------
# Step halving, the IRLS iteration count, and the standard errors that follow
# from it.
#
# The standard errors of a glm come from the information matrix of the
# penultimate IRLS iterate -- in R because summary.glm inverts the QR that
# glm.fit kept from its last weighted least squares call, and here because
# sweep_matrix_ols leaves that same inverse in XtWX. Agreeing with R therefore
# means stopping on the same iteration as R, and glm() used not to: its
# step-halving guard treated any increase in deviance as divergence, but the
# standard IRLS start puts mu at y + 0.1, essentially on the data, so the first
# real step almost always raises the deviance. R halves only for a NON-FINITE
# deviance. The spurious halving cost three extra iterations on the fit below and
# left the standard errors 5e-8 out, while the coefficients still agreed to
# twelve digits -- which is exactly the signature to watch for if this regresses.
#
# R 4.6.1: glm(y ~ x + z, family = poisson) on these nine points reports
# iter = 4, and its deviance sequence from the y + 0.1 start is
#   0.0159923555708651 -> 1.53581563522527 -> 1.51018943054587
#     -> 1.51018274292911 -> 1.51018274292864
# so the very first step raises the deviance by two orders of magnitude.
{
	my %d = (
		y => [ 2, 3, 6, 7, 8, 9, 10, 12, 15 ],
		x => [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ],
		z => [ 1, 1, 2, 2, 3, 3, 4, 4, 5 ],
	);
	my $f = glm(formula => 'y ~ x + z', data => \%d, family => 'poisson');

	is($f->{iter}, 4,
		'glm: poisson IRLS takes the same 4 iterations as R (no spurious halving)');
	ok($f->{converged}, 'glm: poisson fit converged');
	ok(!$f->{boundary},
		'glm: a first step that raises the deviance is not flagged as a boundary');

	# R 4.6.1 summary.glm, to 17 significant figures.
	my %want = (
		Intercept => [ 0.98087147249005948, 0.3441360006423218  ],
		x         => [ 0.19251195025971117, 0.24975146858288139 ],
		z         => [ 0.0045485440892567,  0.47889654233525075 ],
	);
	for my $t (sort keys %want) {
		my ($est, $se) = @{ $want{$t} };
		cmp_ok(abs($f->{coefficients}{$t} - $est), '<', 1e-9 * abs($est),
			"glm: poisson coefficient $t matches R");
		cmp_ok(abs($f->{summary}{$t}{'Std. Error'} - $se), '<', 1e-9 * abs($se),
			"glm: poisson Std. Error for $t matches R");
	}
	cmp_ok(abs($f->{deviance} - 1.5101827429286351), '<', 1e-9,
		'glm: poisson deviance matches R');

	# The bug showed up as coefficients far more accurate than standard errors.
	# Both should now sit at the same order, so compare their agreement directly.
	my ($worst_est, $worst_se) = (0, 0);
	for my $t (sort keys %want) {
		my ($est, $se) = @{ $want{$t} };
		my $de = abs($f->{coefficients}{$t} - $est) / abs($est);
		my $ds = abs($f->{summary}{$t}{'Std. Error'} - $se) / abs($se);
		$worst_est = $de if $de > $worst_est;
		$worst_se  = $ds if $ds > $worst_se;
	}
	cmp_ok($worst_se, '<', 1e-11,
		'glm: standard errors are as accurate as the coefficients, not 1e4 worse');

	# A binomial fit takes more iterations but must still match R's count, since
	# the same penultimate-iterate argument applies.
	# R: glm(am ~ wt + hp, mtcars, family = binomial) reports iter = 8.
	my %mt = (
		am => [ 1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,1,1,1,1,1,1,1 ],
		wt => [ 2.62, 2.875, 2.32, 3.215, 3.44, 3.46, 3.57, 3.19, 3.15, 3.44,
		        3.44, 4.07, 3.73, 3.78, 5.25, 5.424, 5.345, 2.2, 1.615, 1.835,
		        2.465, 3.52, 3.435, 3.84, 3.845, 1.935, 2.14, 1.513, 3.17,
		        2.77, 3.57, 2.78 ],
		hp => [ 110, 110, 93, 110, 175, 105, 245, 62, 95, 123, 123, 180, 180,
		        180, 205, 215, 230, 66, 52, 65, 97, 150, 150, 245, 175, 66, 91,
		        113, 264, 175, 335, 109 ],
	);
	my $b = glm(formula => 'am ~ wt + hp', data => \%mt, family => 'binomial');
	is($b->{iter}, 8, 'glm: binomial IRLS takes the same 8 iterations as R');
	# R 4.6.1 summary.glm(am ~ wt + hp, binomial)
	my %bwant = (
		Intercept => [ 18.866298717204096,   7.443558060205274   ],
		wt        => [ -8.0834751824446283,  3.0686751130546961  ],
		hp        => [  0.036255596082216547, 0.017734153650769347 ],
	);
	for my $t (sort keys %bwant) {
		my ($est, $se) = @{ $bwant{$t} };
		cmp_ok(abs($b->{coefficients}{$t} - $est), '<', 1e-8 * abs($est),
			"glm: binomial coefficient $t matches R");
		cmp_ok(abs($b->{summary}{$t}{'Std. Error'} - $se), '<', 1e-8 * abs($se),
			"glm: binomial Std. Error for $t matches R");
	}
}

done_testing();
