#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 2;
use Numeric::Matrix;

my $a = Numeric::Matrix::from_array([10, 20, 30, 40], 2, 2);
my $b = Numeric::Matrix::from_array([1, 2, 3, 4], 2, 2);
$a->sub_inplace($b);

is($a->get(0, 0), 9, 'sub_inplace [0,0]');
is($a->get(1, 1), 36, 'sub_inplace [1,1]');
