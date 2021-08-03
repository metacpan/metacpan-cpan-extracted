#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;
use Object::Pad::SlotAttr::Final;

my $compile_warnings;
BEGIN { $SIG{__WARN__} = sub { $compile_warnings .= $_[0] }; }

class Example {
   has $slot :reader :writer :param :Final;

   ADJUST { $slot = uc $slot }

   method mutate { $slot = "different" }
}

BEGIN { undef $SIG{__WARN__}; }

like( $compile_warnings, qr/^Applying :Final attribute to slot \$slot which already has :writer at /,
   'Compiletime warning from :writer + :Final combined' );

{
   my $obj = Example->new( slot => "the value" );
   is( $obj->slot, "THE VALUE", '$obj->slot retrives value after ADJUST' );

   my $e;

   ok( !defined eval { $obj->set_slot( "changed" ) },
      '$obj->set_slot dies' );
   $e = $@;
   like( $e, qr/^Modification of a read-only value attempted at /,
      'Failure message from writer method attempt' );
}

done_testing;
