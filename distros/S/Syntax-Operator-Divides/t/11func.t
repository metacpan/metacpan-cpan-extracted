#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Operator::Divides qw( is_divisor );

ok( is_divisor( 15, 5 ), '15 divides into 5');
ok(!is_divisor( 16, 5 ), '16 does not divide into 5');

done_testing;
