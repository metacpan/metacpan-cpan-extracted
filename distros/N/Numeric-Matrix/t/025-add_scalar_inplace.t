#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 2;
use Numeric::Matrix;

my $a = Numeric::Matrix::from_array([1, 2, 3, 4], 2, 2);
$a->add_scalar_inplace(10);

is($a->get(0, 0), 11, 'add_scalar_inplace [0,0]');
is($a->get(1, 1), 14, 'add_scalar_inplace [1,1]');
