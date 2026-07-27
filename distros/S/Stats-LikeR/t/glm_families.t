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

	is($nb->{family}, 'negbin', 'negbin family recorded');
	is_approx($nb->{coefficients}{Intercept}, 1.74919985, 'negbin intercept');
	is_approx($nb->{coefficients}{xb},         0.19671029, 'negbin xb');
	is_approx($nb->{coefficients}{xc},         0.56443507, 'negbin xc');
	is_approx($nb->{theta},                    0.37259793, 'negbin theta (ML)', 1e-4);
	is_approx($nb->{deviance},                26.90313164, 'negbin deviance', 1e-4);
	is_approx($nb->{'null.deviance'},         27.40893518, 'negbin null deviance', 1e-4);
	is_approx($nb->{aic},                    151.38797261, 'negbin AIC', 1e-3);
	is_approx($nb->{summary}{Intercept}{'Std. Error'}, 0.59768001, 'negbin SE intercept', 1e-5);
	is_approx($nb->{summary}{xb}{'Std. Error'},        0.84294769, 'negbin SE xb', 1e-5);
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

done_testing();
