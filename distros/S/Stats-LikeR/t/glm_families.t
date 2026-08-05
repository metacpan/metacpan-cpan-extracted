#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception;
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# Floating-point comparison helper (mirrors t/cor.t / t/epi_2x2.t).
sub is_approx {
	my ($got, $expected, $test_name, $epsilon) = @_;
	$epsilon = 1e-6 if not defined $epsilon;
	my $diff = abs($got - $expected);
	if ($diff <= $epsilon) { pass("$test_name: within $epsilon"); return 1; }
	fail($test_name);
	diag("         got: $got\n    expected: $expected; diff = $diff");
	return 0;
}

#--------------------------------------------------------------------------
# Poisson log-linear model.  Reference values from R:
#   glm(y ~ x + g, family = poisson)
#--------------------------------------------------------------------------
{
	my @y = (1,3,0,2,5,4,7,2,1,6,3,8,0,4,2,5,9,1,3,6);
	my @x = (0.5,1.2,0.3,0.9,2.1,1.7,2.8,1.0,0.6,2.4,
	         1.4,3.0,0.2,1.9,1.1,2.2,3.3,0.7,1.5,2.6);
	my @g = (qw(A A B B A B A B A A B B A B A B A B A B));
	my $p = glm(formula => 'y ~ x + g', data => { y => \@y, x => \@x, g => \@g },
	            family => 'poisson');

	is($p->{family}, 'poisson', 'poisson family recorded');
	is_approx($p->{coefficients}{Intercept}, -0.2191426131, 'poisson intercept');
	is_approx($p->{coefficients}{x},           0.7804336270, 'poisson x');
	is_approx($p->{coefficients}{gB},          0.0387865642, 'poisson gB');
	is_approx($p->{deviance},                  5.7236550499, 'poisson deviance');
	is_approx($p->{'null.deviance'},          41.0738580500, 'poisson null deviance');
	is_approx($p->{aic},                      67.1471337804, 'poisson AIC', 1e-5);
	# SEs come from the normal-equations (X'WX) solve rather than R's QR, so
	# they agree with R to ~6 significant figures rather than to machine eps.
	is_approx($p->{summary}{Intercept}{'Std. Error'}, 0.3605544731, 'poisson SE intercept', 1e-5);
	is_approx($p->{summary}{x}{'Std. Error'},         0.1380109306, 'poisson SE x', 1e-5);
	is_approx($p->{summary}{gB}{'Std. Error'},        0.2379512453, 'poisson SE gB', 1e-5);
	# z value / p-value use the normal distribution for count families
	ok(exists $p->{summary}{x}{'z value'}, 'poisson reports z value');
	ok(exists $p->{summary}{x}{'Pr(>|z|)'}, 'poisson reports Pr(>|z|)');

	# exp(beta) = rate ratio with Wald CI (confint.default)
	is_approx($p->{exp}{x}{estimate},  2.1824184158, 'poisson x rate ratio', 1e-5);
	is_approx($p->{exp}{x}{'conf.low'},  1.6651865738, 'poisson x RR CI lower', 1e-5);
	is_approx($p->{exp}{x}{'conf.high'}, 2.8603101999, 'poisson x RR CI upper', 1e-4);
	is_approx($p->{'conf.int'}{x}[0], log(1.6651865738), 'poisson conf.int lower (link scale)', 1e-5);
	is_approx($p->{'conf.level'}, 0.95, 'default conf.level 0.95', 1e-9);
}

#--------------------------------------------------------------------------
# Negative-binomial with ML-estimated theta.  Reference values from R:
#   MASS::glm.nb(y ~ x)   (x a 3-level factor, genuinely overdispersed)
#--------------------------------------------------------------------------
{
	my @y = (0,8,1,0,15,2,20,0,1,9,0,30,3,0,12,1,25,0,2,18,0,1,40,0,5);
	my @x = (qw(a a a a a a a a b b b b b b b b c c c c c c c c c));
	my $nb = glm(formula => 'y ~ x', data => { y => \@y, x => \@x }, family => 'negbin');

	# Reference values to 17 significant figures from MASS 7.3 glm.nb, and the
	# tolerances are what the fit actually achieves against them rather than the
	# 1e-3/1e-4 they used to be: the theta alternation now follows glm.nb's own
	# schedule (a Poisson first pass, warm-started refits, theta re-estimated at
	# the means each pass started from, and glm.nb's convergence test), so the
	# coefficients land within a few ulp and theta within 1e-11.
	is($nb->{family}, 'negbin', 'negbin family recorded');
	is_approx($nb->{coefficients}{Intercept}, 1.7491998548092598, 'negbin intercept', 1e-11);
	is_approx($nb->{coefficients}{xb},        0.1967102942460536, 'negbin xb',        1e-11);
	is_approx($nb->{coefficients}{xc},        0.5644350743713713, 'negbin xc',        1e-11);
	is_approx($nb->{theta},                   0.37259793467405294, 'negbin theta (ML)', 1e-9);
	is_approx($nb->{deviance},               26.903131638251899, 'negbin deviance',   1e-8);
	is_approx($nb->{'null.deviance'},        27.408935175506617, 'negbin null deviance', 1e-8);
	is_approx($nb->{aic},                   151.38797261447414,  'negbin AIC',        1e-10);
	is_approx($nb->{summary}{Intercept}{'Std. Error'}, 0.59768001301775331,
		'negbin SE intercept', 1e-9);
	is_approx($nb->{summary}{xb}{'Std. Error'},        0.84294769015886351,
		'negbin SE xb', 1e-9);
	is_approx($nb->{summary}{xc}{'Std. Error'},        0.8163435973737585,
		'negbin SE xc', 1e-9);
	ok($nb->{converged}, 'negbin converged');
	ok(exists $nb->{exp}{xb}, 'negbin reports exp (incidence-rate ratios)');

	# theta may be supplied to fix the dispersion (no ML step)
	my $fixed = glm(formula => 'y ~ x', data => { y => \@y, x => \@x },
	                family => 'negbin', theta => 0.37259793);
	is_approx($fixed->{coefficients}{Intercept}, 1.74919985, 'fixed-theta intercept', 1e-4);
}

#--------------------------------------------------------------------------
# Error handling
#--------------------------------------------------------------------------
throws_ok { glm(formula => 'y ~ x', data => { y => [1,2], x => [1,2] },
                family => 'weibull') } qr/unsupported family/, 'rejects unknown family';
throws_ok { glm(formula => 'y ~ x', data => { y => [-1,2,3], x => [1,2,3] },
                family => 'poisson') } qr/non-negative/, 'poisson rejects negative counts';

#--------------------------------------------------------------------------
# Leak check (clean, converging data only)
#--------------------------------------------------------------------------
no_leaks_ok {
	my @y = (0,8,1,0,15,2,20,0,1,9,0,30,3,0,12,1,25,0,2,18,0,1,40,0,5);
	my @x = (qw(a a a a a a a a b b b b b b b b c c c c c c c c c));
	glm(formula => 'y ~ x', data => { y => \@y, x => \@x }, family => 'negbin');
	glm(formula => 'y ~ x', data => { y => \@y, x => \@x }, family => 'poisson');
} 'glm poisson/negbin does not leak';

#--------------------------------------------------------------------------
# Negative binomial across dispersion regimes, against MASS 7.3 glm.nb.
#
# glm.nb does not simply maximise over theta; it alternates, and which fit it
# lands on depends on the schedule. Reproducing it means matching four things:
#
#   1. The first pass is an ordinary POISSON fit. Its fitted means give the first
#      theta and its residual df set the scale d1 in the convergence test.
#   2. Later passes are warm started from the previous means (etastart = log(mu)).
#   3. theta is re-estimated at the means each pass STARTED from, not the ones it
#      produced -- glm.nb calls theta.ml(Y, mu) before reassigning mu.
#   4. Convergence is (|dLm| / d1 + |dtheta|) < 1e-8, with
#      d1 = sqrt(2 * max(1, df.residual)) from the Poisson pass.
#
# Before those were in place the alternation stopped early -- a relative test on
# the log-likelihood alone -- leaving theta 8e-7 out and the coefficients 8e-6.
#--------------------------------------------------------------------------
{
	my @x = (0.341, 1.867, 1.828, 1.87, 2.583, 1.921, 0.028, 0.698, 1.998, 1.543,
	         2.081, 1.635, 0.848, 2.77, 0.877, 2.512, 0.859, 0.8, 0.56, 0.697,
	         0.95, 0.908, 0.477, 0.12, 0.656, 2.432, 1.577, 2.744, 2.494, 0.137,
	         1.368, 0.796, 0.914, 1.522, 0.543, 2.279, 0.604, 0.776, 2.976, 2.422,
	         1.66, 1.939, 0.935, 1.865, 0.989, 1.506, 2.031, 1.455, 0.732, 2.296,
	         0.221, 0.929, 2.152, 1.514, 0.459, 1.512, 1.482, 2.254, 0.524, 2.545);
	my @y = (3, 2, 5, 11, 6, 5, 3, 6, 3, 7, 1, 2, 1, 12, 4, 19, 3, 2, 6, 8, 3, 7,
	         4, 6, 9, 8, 5, 8, 9, 4, 3, 2, 9, 9, 2, 15, 5, 5, 11, 14, 3, 14, 4,
	         11, 5, 4, 5, 8, 5, 6, 8, 8, 4, 5, 5, 7, 1, 13, 3, 7);
	my @g = map { $_ % 2 ? 'b' : 'a' } 0 .. 59;

	# MASS: glm.nb(y ~ x + g) -- moderate overdispersion, theta about 14.7
	my $nb = glm(formula => 'y ~ x + g', data => { y => \@y, x => \@x, g => \@g },
	             family => 'negbin');
	ok($nb->{converged}, 'negbin (mild): alternation converged');
	is_approx($nb->{theta}, 14.685839324389679, 'negbin (mild): theta matches glm.nb', 1e-7);
	is_approx($nb->{coefficients}{Intercept}, 1.1650268824008592,
		'negbin (mild): intercept matches glm.nb', 1e-9);
	is_approx($nb->{coefficients}{x}, 0.28642703233678113,
		'negbin (mild): x matches glm.nb', 1e-9);
	is_approx($nb->{coefficients}{gb}, 0.40422757248145458,
		'negbin (mild): gb matches glm.nb', 1e-9);
	is_approx($nb->{summary}{Intercept}{'Std. Error'}, 0.1471152110964421,
		'negbin (mild): SE intercept matches glm.nb', 1e-9);
	is_approx($nb->{summary}{x}{'Std. Error'}, 0.083075914303464768,
		'negbin (mild): SE x matches glm.nb', 1e-9);
	is_approx($nb->{summary}{gb}{'Std. Error'}, 0.13123560475743437,
		'negbin (mild): SE gb matches glm.nb', 1e-9);
	is_approx($nb->{deviance}, 61.322438800810708,
		'negbin (mild): deviance matches glm.nb', 1e-7);
	is_approx($nb->{aic}, 300.379062123121, 'negbin (mild): AIC matches glm.nb', 1e-7);
}

#--------------------------------------------------------------------------
# Near-Poisson data, where theta is barely identified.
#
# These counts are drawn from a Poisson, so the likelihood is almost flat in
# theta: MASS reports theta = 35.8 with a standard error larger than the estimate,
# and on data one step further toward Poisson glm.nb's own theta.ml stops with
# "iteration limit reached". Theta is therefore held only loosely here -- what has
# to agree tightly is the regression coefficients, which is what the model is for
# and which barely move with theta at this scale.
#--------------------------------------------------------------------------
{
	my @x = (2.756, 2.353, 2.213, 0.842, 1.37, 0.863, 2.089, 2.462, 1.965, 1.241,
	         2.855, 0.729, 1.826, 2.274, 2.081, 0.346, 1.908, 0.927, 1.059, 2.943,
	         1.617, 1.332, 2.848, 1.357, 0.572, 2.975, 1.645, 2.306, 2.74, 2.046,
	         1.222, 1.223, 0.438, 0.59, 0.577, 1.225, 1.045, 2.504, 0.595, 2.585,
	         1.192, 0.46, 1.018, 1.102, 1.282, 0.559, 1.974, 2.761, 2.202, 2.647);
	my @y = (15, 6, 8, 5, 6, 2, 13, 8, 13, 5, 10, 5, 6, 4, 9, 9, 4, 4, 8, 6, 12,
	         7, 12, 9, 0, 10, 6, 12, 17, 9, 5, 9, 7, 11, 4, 10, 6, 8, 5, 12, 4, 5,
	         7, 5, 5, 0, 5, 7, 5, 11);

	my $nb = glm(formula => 'y ~ x', data => { y => \@y, x => \@x }, family => 'negbin');
	ok($nb->{converged}, 'negbin (near-Poisson): alternation converged');
	# MASS: theta = 35.818627515380101, with theta.ml's own SE above 30
	is_approx($nb->{theta}, 35.818627515380101,
		'negbin (near-Poisson): theta matches glm.nb to 1e-4 absolute', 1e-4);
	is_approx($nb->{coefficients}{Intercept}, 1.4469704755863968,
		'negbin (near-Poisson): intercept matches glm.nb', 1e-9);
	is_approx($nb->{coefficients}{x}, 0.32085281002533184,
		'negbin (near-Poisson): x matches glm.nb', 1e-9);
	is_approx($nb->{summary}{Intercept}{'Std. Error'}, 0.14254556092089382,
		'negbin (near-Poisson): SE intercept matches glm.nb', 1e-8);
	is_approx($nb->{summary}{x}{'Std. Error'}, 0.072386223628592289,
		'negbin (near-Poisson): SE x matches glm.nb', 1e-8);
	is_approx($nb->{deviance}, 59.782499363704837,
		'negbin (near-Poisson): deviance matches glm.nb', 1e-6);

	# A supplied theta skips the alternation entirely, which is the same thing as
	# R's glm(family = negative.binomial(theta = ...)).
	#   R: glm(y ~ x, family = negative.binomial(theta = 35.818627515380101))
	#      Intercept 1.446970465348421  se 0.14840719528485938
	#      x         0.3208528155098585 se 0.07536261296481149
	my $fix = glm(formula => 'y ~ x', data => { y => \@y, x => \@x },
	              family => 'negbin', theta => 35.818627515380101);
	is_approx($fix->{theta}, 35.818627515380101,
		'negbin: a supplied theta is used exactly as given', 0);
	is_approx($fix->{coefficients}{Intercept}, 1.446970465348421,
		'negbin fixed theta: intercept matches R negative.binomial()', 1e-12);
	is_approx($fix->{coefficients}{x}, 0.3208528155098585,
		'negbin fixed theta: x matches R negative.binomial()', 1e-12);
	# Standard errors here hold the dispersion at 1, which is what glm.nb and
	# summary.negbin do. R's summary.glm, handed a negative.binomial family,
	# instead ESTIMATES the dispersion -- 1.0839 on this data -- and so prints
	# standard errors sqrt(1.0839) larger (0.0754 rather than 0.0724 for x). The
	# comparison below is against summary(fit, dispersion = 1), the convention
	# this module follows for a family whose variance is already fully specified.
	is_approx($fix->{summary}{Intercept}{'Std. Error'}, 0.142545635249742869,
		'negbin fixed theta: SE intercept matches R at dispersion 1', 1e-12);
	is_approx($fix->{summary}{x}{'Std. Error'}, 0.072386055935695803,
		'negbin fixed theta: SE x matches R at dispersion 1', 1e-12);

	# Refitting at the theta the alternation reported does NOT reproduce the
	# alternation's own coefficients, and must not be expected to: glm.nb returns
	# the fit from before its final theta update, so the reported coefficients go
	# with the previous theta. MASS shows the same gap on this data -- 5.5e-9 on x
	# between glm.nb and a refit at glm.nb's own theta -- so the two are expected
	# to differ by about that much and no more.
	my $gap = abs($fix->{coefficients}{x} - $nb->{coefficients}{x});
	cmp_ok($gap, '<', 1e-7,
		'negbin: the reported fit sits one theta behind, as in glm.nb');
	cmp_ok($gap, '>', 0,
		'negbin: and it really is a different fit, not an artefact of rounding');
}

done_testing();
