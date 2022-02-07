#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;
use Object::Pad::FieldAttr::Final;

class Example {
   has $field :reader :param :Final;

   ADJUST { $field = uc $field }

   method mutate { $field = "different" }
}

{
   my $obj = Example->new( field => "the value" );
   is( $obj->field, "THE VALUE", '$obj->field retrives value after ADJUST' );

   my $e;

   ok( !defined eval { $obj->mutate },
      'Direct field assignment dies' );
   $e = $@;
   like( $e, qr/^Modification of a read-only value attempted at /,
      'Failure message from assignment attempt' );
}

done_testing;
