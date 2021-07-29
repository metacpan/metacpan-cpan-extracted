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

         $rolemeta->add_slot( '$slot',
            param => "role_slot",
            reader => "get_role_slot",
         );
      }
   }
}

{
   class AClass does ARole {}

   my $obj = AClass->new( role_slot => "the slot value" );
   is( $obj->get_role_slot, "the slot value", 'instance slot accessible via role' );
}

done_testing;
