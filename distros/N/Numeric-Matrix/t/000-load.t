#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 5;

use_ok('Numeric::Matrix');
ok(Numeric::Matrix->can('zeros'), 'can zeros');
ok(Numeric::Matrix->can('ones'), 'can ones');
ok(Numeric::Matrix->can('randn'), 'can randn');
ok(Numeric::Matrix->can('from_array'), 'can from_array');
