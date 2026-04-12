#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 4;
use Numeric::Matrix;

my $m = Numeric::Matrix::from_array([1..6], 2, 3);
my $z = $m->zeros_like;

ok(ref($z) eq 'Numeric::Matrix', 'isa Numeric::Matrix');
is($z->rows, 2, 'same rows');
is($z->cols, 3, 'same cols');
is($z->sum, 0, 'all zeros');
