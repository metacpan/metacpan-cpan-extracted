#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

BEGIN {
   eval { require Types::Standard } or
      plan skip_all => "Types::Standard is not available";
}

use Sublike::Extended;
use Signature::Attribute::Checked;

use experimental 'signatures';

{
   use Types::Standard qw( Num );

   extended sub f ($x :Checked(Num)) { return $x + 1 }
}

{
   ok( lives { f( 0 ) },
      'f with number OK' );
   is( f( 10 ), 11,
      'f sees correct param value' );

   like( dies { f( "zero" ) },
      qr/^Parameter \$x requires a value satisfying Num /,
      'f with string throws' );
}

{
   use Types::Standard qw( Maybe Num );

   extended sub g ($x :Checked(Maybe[Num])) { return $x }
}

{
   ok( lives { g( 0 ) },
      'g with number OK' );
   ok( lives { g( undef ) },
      'g with undef OK' );

   like( dies { g( "zero" ) },
      qr/^Parameter \$x requires a value satisfying Maybe\[Num\] /,
      'g with string throws' );
}

done_testing;
