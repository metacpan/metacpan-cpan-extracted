#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 3;
use Numeric::Matrix;

my $a = Numeric::Matrix::from_array([1, exp(1), exp(2), exp(3)], 2, 2);
my $b = $a->log;

ok(ref($b) eq 'Numeric::Matrix', 'isa Numeric::Matrix');
approx_eq($b->get(0, 0), 0, 1e-10, 'log(1) = 0');
approx_eq($b->get(0, 1), 1, 1e-10, 'log(e) = 1');
