#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

BEGIN {
   plan skip_all => "Syntax::Operator::In >= 0.03 is not available"
      unless eval { require Syntax::Operator::In;
                    Syntax::Operator::In->VERSION( '0.03' ) };
   plan skip_all => "Syntax::Operator::Equ is not available"
      unless eval { require Syntax::Operator::Equ; };

   Syntax::Operator::In->import;
   Syntax::Operator::Equ->import;

   diag( "Syntax::Operator::In $Syntax::Operator::In::VERSION, " .
         "Syntax::Operator::Equ $Syntax::Operator::Equ::VERSION" );
}

BEGIN { plan skip_all => "No PL_infix_plugin" unless XS::Parse::Infix::HAVE_PL_INFIX_PLUGIN; }

ok(    0 in:=== (0..4) , '0 is in 0..4 by ===');
ok(not(6 in:=== (0..4)), '6 is not in 0..4 by ===');

ok(    undef in:=== (1, undef, 3), 'undef is in list containing undef by ===');
ok(not(undef in:=== (0..4)), 'undef is not in 0..4 by ===');

ok(    'a' in:equ ('a'..'e') , 'a is in a..e by equ');
ok(not('f' in:equ ('a'..'e')), 'f is not in a..e by equ');

ok(    undef in:equ ('a', undef, 'c'), 'undef is in list containing undef by equ');
ok(not(undef in:equ ('a', '', 'c')), 'undef is not in list containing empty string by equ');

done_testing;
