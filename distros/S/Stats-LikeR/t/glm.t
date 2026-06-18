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

done_testing();
