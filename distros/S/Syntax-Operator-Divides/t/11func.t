#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Operator::Divides qw( is_divisor );

ok( is_divisor( 15, 5 ), '15 divides into 5');
ok(!is_divisor( 16, 5 ), '16 does not divide into 5');

no Syntax::Operator::Divides qw( is_divisor );

like( dies { is_divisor( 10, 1 ) },
   qr/^Undefined subroutine &main::is_divisor called at /,
   'unimport' );

done_testing;
