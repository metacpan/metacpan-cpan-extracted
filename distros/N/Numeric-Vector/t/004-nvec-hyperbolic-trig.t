#!/usr/bin/perl
use strict;
use warnings;
use Test2::Bundle::Numerical qw(:all);
use Numeric::Vector;

# Test hyperbolic functions: sinh, cosh, tanh
my $v = Numeric::Vector::new([0, 1, -1, 0.5]);

# sinh tests
my $sinh_result = $v->sinh();
ok(abs($sinh_result->get(0) - 0) < 0.0001, 'sinh(0) = 0');
ok(abs($sinh_result->get(1) - 1.1752) < 0.001, 'sinh(1) ~= 1.1752');
ok(abs($sinh_result->get(2) + 1.1752) < 0.001, 'sinh(-1) ~= -1.1752');

# cosh tests
my $cosh_result = $v->cosh();
ok(abs($cosh_result->get(0) - 1) < 0.0001, 'cosh(0) = 1');
ok(abs($cosh_result->get(1) - 1.5431) < 0.001, 'cosh(1) ~= 1.5431');
ok(abs($cosh_result->get(2) - 1.5431) < 0.001, 'cosh(-1) ~= 1.5431 (even function)');

# tanh tests
my $tanh_result = $v->tanh();
ok(abs($tanh_result->get(0) - 0) < 0.0001, 'tanh(0) = 0');
ok(abs($tanh_result->get(1) - 0.7616) < 0.001, 'tanh(1) ~= 0.7616');
ok(abs($tanh_result->get(2) + 0.7616) < 0.001, 'tanh(-1) ~= -0.7616');

# atan tests
my $v2 = Numeric::Vector::new([0, 1, -1, 0.5]);
my $atan_result = $v2->atan();
ok(abs($atan_result->get(0) - 0) < 0.0001, 'atan(0) = 0');
ok(abs($atan_result->get(1) - 0.7854) < 0.001, 'atan(1) ~= pi/4');
ok(abs($atan_result->get(2) + 0.7854) < 0.001, 'atan(-1) ~= -pi/4');

done_testing();
