#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 4;
use Numeric::Matrix;

my $m = Numeric::Matrix::from_array([1, 2, 3, 4, 5, 6, 7, 8, 9], 3, 3);
my $s = $m->slice_rows(1, 3);

ok(ref($s) eq 'Numeric::Matrix', 'isa Numeric::Matrix');
is($s->rows, 2, 'sliced rows');
is($s->cols, 3, 'preserved cols');
is($s->get(0, 0), 4, 'first element of slice');
