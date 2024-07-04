#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use Sublike::Extended;
use Signature::Attribute::Checked;

use experimental 'signatures';

use Data::Checks 0.04 qw( Num Maybe );

extended sub f ($x :Checked(Num)) { return $x + 1 }

{
   ok( lives { f( 0 ) },
      'f with number OK' );
   is( f( 10 ), 11,
      'f sees correct param value' );

   like( dies { f( "zero" ) },
      qr/^Parameter \$x requires a value satisfying :Checked\(Num\) /,
      'f with string throws' );
}

extended sub g ($x :Checked(Maybe Num)) { return $x }

{
   ok( lives { g( 0 ) },
      'g with number OK' );
   ok( lives { g( undef ) },
      'g with undef OK' );

   like( dies { g( "zero" ) },
      qr/^Parameter \$x requires a value satisfying :Checked\(Maybe Num\) /,
      'g with string throws' );
}

done_testing;
