#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Operator::Divides;
BEGIN { plan skip_all => "No PL_infix_plugin" unless XS::Parse::Infix::HAVE_PL_INFIX_PLUGIN; }

ok(  15 %% 5 , '15 divides into 5');
ok(!(16 %% 5), '16 does not divide into 5');

# unimport
{
   no Syntax::Operator::Divides;

   # %% isn't usable as a symbol name but we can hack something up
   my %three = ( 1 => 1, 2 => 2, 3 => 3 );

   # 8 mod 3 == 2
   is( 8%%three, 2, '%%name parses as % %hash operator' );
}

done_testing;
