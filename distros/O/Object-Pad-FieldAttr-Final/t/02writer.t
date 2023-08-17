#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Object::Pad;
use Object::Pad::FieldAttr::Final;

my $compile_warnings;
BEGIN { $SIG{__WARN__} = sub { $compile_warnings .= $_[0] }; }

class Example {
   field $field :reader :writer :param :Final;

   ADJUST { $field = uc $field }

   method mutate { $field = "different" }
}

BEGIN { undef $SIG{__WARN__}; }

like( $compile_warnings, qr/^Applying :Final attribute to field \$field which already has :writer at /,
   'Compiletime warning from :writer + :Final combined' );

{
   my $obj = Example->new( field => "the value" );
   is( $obj->field, "THE VALUE", '$obj->field retrives value after ADJUST' );

   my $e;

   ok( !defined eval { $obj->set_field( "changed" ) },
      '$obj->set_field dies' );
   $e = $@;
   like( $e, qr/^Modification of a read-only value attempted at /,
      'Failure message from writer method attempt' );
}

done_testing;
