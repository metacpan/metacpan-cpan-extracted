#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800 ':experimental(mop)';

{
   package AClass {
      BEGIN {
         Object::Pad->import_into( "AClass" );

         my $classmeta = Object::Pad::MOP::Class->begin_class( "AClass" );

         ::is( $classmeta->name, "AClass", '$classmeta->name' );
      }

      method message { return "Hello" }
   }

   is( AClass->new->message, "Hello",
      '->begin_class can create a class' );
}

class Parent { field $thing = "parent"; }

{
   package Child {
      BEGIN {
         Object::Pad->import_into( "Child" );

         my $classmeta = Object::Pad::MOP::Class->begin_class( "Child", isa => "Parent" );

         ::is( $classmeta->name, "Child", '$classmeta->name for Child' );
      }
      field $other = "child";
      method other { return $other }
   }

   is( Child->new->other, "child",
      '->begin_class can extend superclasses' );
}

done_testing;
