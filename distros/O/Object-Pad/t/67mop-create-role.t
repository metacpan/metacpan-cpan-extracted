#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

{
   package ARole {
      BEGIN {
         Object::Pad->import_into( "ARole" );

         my $rolemeta = Object::Pad::MOP::Class->begin_role( "ARole" );

         $rolemeta->add_field( '$field',
            param => "role_field",
            reader => "get_role_field",
         );
      }
   }
}

{
   class AClass :does(ARole) {}

   my $obj = AClass->new( role_field => "the field value" );
   is( $obj->get_role_field, "the field value", 'instance field accessible via role' );
}

done_testing;
