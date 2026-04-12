#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 2;
use Numeric::Matrix;

my $m = Numeric::Matrix::zeros(3, 4);
is($m->rows, 3, 'rows accessor');

my $m2 = Numeric::Matrix::from_array([1..6], 2, 3);
is($m2->rows, 2, 'rows from array');
