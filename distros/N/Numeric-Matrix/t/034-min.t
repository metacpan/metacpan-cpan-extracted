#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 2;
use Numeric::Matrix;

my $a = Numeric::Matrix::from_array([1, 5, 2, 4, 3, 6], 2, 3);
is($a->min, 1, 'min of 1..6');

my $b = Numeric::Matrix::from_array([-5, -2, -10, -1], 2, 2);
is($b->min, -10, 'min of negatives');
