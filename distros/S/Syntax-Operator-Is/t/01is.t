#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Operator::Is;
BEGIN { plan skip_all => "No PL_infix_plugin" unless XS::Parse::Infix::HAVE_PL_INFIX_PLUGIN; }

use Data::Checks qw( Num );

ok(    123 is Num,       '123 is Num' );
ok( !( undef is Num ),   'undef is not Num' );
ok( !( "hello" is Num ), '"hello" is not Num' );

# Defeat const-folding to prove that pp_is_dynamic also works
my $constraint_Num = Num;
ok(   456 is $constraint_Num,      '456 is Num via padsv' );
ok( !( undef is $constraint_Num ), 'undef is not Num via padsv' );

done_testing;
