#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 2;
use Numeric::Matrix;

my $a = Numeric::Matrix::from_array([10, 20, 30, 40], 2, 2);
my $b = Numeric::Matrix::from_array([2, 4, 5, 8], 2, 2);
$a->div_inplace($b);

is($a->get(0, 0), 5, 'div_inplace [0,0]');
is($a->get(1, 1), 5, 'div_inplace [1,1]');
