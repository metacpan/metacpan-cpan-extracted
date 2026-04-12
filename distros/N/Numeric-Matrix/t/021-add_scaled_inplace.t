#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 2;
use Numeric::Matrix;

my $a = Numeric::Matrix::from_array([1, 2, 3, 4], 2, 2);
my $b = Numeric::Matrix::from_array([10, 20, 30, 40], 2, 2);
$a->add_scaled_inplace($b, 0.5);

is($a->get(0, 0), 6, 'add_scaled_inplace [0,0]: 1 + 0.5*10');
is($a->get(1, 1), 24, 'add_scaled_inplace [1,1]: 4 + 0.5*40');
