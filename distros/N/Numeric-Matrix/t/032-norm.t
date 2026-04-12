#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 2;
use Numeric::Matrix;

my $a = Numeric::Matrix::from_array([3, 4], 1, 2);
is($a->norm, 5, 'norm of [3,4] = 5');

my $b = Numeric::Matrix::from_array([1, 0, 0, 0], 2, 2);
is($b->norm, 1, 'norm of unit');
