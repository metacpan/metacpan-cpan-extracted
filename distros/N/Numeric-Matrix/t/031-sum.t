#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 2;
use Numeric::Matrix;

my $a = Numeric::Matrix::from_array([1, 2, 3, 4, 5, 6], 2, 3);
is($a->sum, 21, 'sum of 1..6');

my $z = Numeric::Matrix::zeros(3, 3);
is($z->sum, 0, 'sum of zeros');
