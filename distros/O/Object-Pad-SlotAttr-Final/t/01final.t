#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;
use Object::Pad::SlotAttr::Final;

class Example {
   has $slot :reader :writer :param :Final;

   ADJUST { $slot = uc $slot }

   method mutate { $slot = "different" }
}

{
   my $obj = Example->new( slot => "the value" );
   is( $obj->slot, "THE VALUE", '$obj->slot retrives value after ADJUST' );

   my $e;

   ok( !defined eval { $obj->mutate },
      'Direct slot assignment dies' );
   $e = $@;
   like( $e, qr/^Modification of a read-only value attempted at /,
      'Failure message from assignment attempt' );

   ok( !defined eval { $obj->set_slot( "changed" ) },
      '$obj->set_slot dies' );
   $e = $@;
   like( $e, qr/^Modification of a read-only value attempted at /,
      'Failure message from writer method attempt' );
}

done_testing;
