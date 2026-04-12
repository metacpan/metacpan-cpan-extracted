#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 4;
use Numeric::Matrix;

my $m = Numeric::Matrix::from_vector([1, 2, 3, 4, 5, 6], 2, 3);
ok(ref($m) eq 'Numeric::Matrix', 'isa Numeric::Matrix');
is($m->rows, 2, 'rows');
is($m->cols, 3, 'cols');
is($m->sum, 21, 'sum');
