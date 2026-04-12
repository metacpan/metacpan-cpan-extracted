#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 5;
use Numeric::Matrix;

my $m = Numeric::Matrix::zeros(3, 4);
ok(ref($m) eq 'Numeric::Matrix', 'isa Numeric::Matrix');
is($m->rows, 3, 'rows');
is($m->cols, 4, 'cols');
is($m->sum, 0, 'sum of zeros');
is($m->get(0, 0), 0, 'element value');
