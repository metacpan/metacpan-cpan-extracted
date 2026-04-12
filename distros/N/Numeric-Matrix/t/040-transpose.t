#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 4;
use Numeric::Matrix;

my $a = Numeric::Matrix::from_array([1, 2, 3, 4, 5, 6], 2, 3);
my $t = $a->transpose;

ok(ref($t) eq 'Numeric::Matrix', 'isa Numeric::Matrix');
is($t->rows, 3, 'transposed rows');
is($t->cols, 2, 'transposed cols');
is($t->get(2, 1), 6, 'transposed element');
