#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 3;
use Numeric::Matrix;

my $a = Numeric::Matrix::from_array([0, 1, 2, 3], 2, 2);
my $b = $a->exp;

ok(ref($b) eq 'Numeric::Matrix', 'isa Numeric::Matrix');
approx_eq($b->get(0, 0), 1, 1e-10, 'exp(0) = 1');
approx_eq($b->get(0, 1), exp(1), 1e-10, 'exp(1)');
