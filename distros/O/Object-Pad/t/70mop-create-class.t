#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Object::Pad;

{
   package AClass {
      BEGIN {
         Object::Pad->import_into( "AClass" );
         Object::Pad->begin_class( "AClass" );
      }

      method message { return "Hello" }
   }

   is( AClass->new->message, "Hello",
      '->begin_class can create a class' );
}

class Parent { has $thing = "parent"; }

{
   package Child {
      BEGIN {
         Object::Pad->import_into( "Child" );
         Object::Pad->begin_class( "Child", extends => "Parent" );
      }
      has $other = "child";
      method other { return $other }
   }

   is( Child->new->other, "child",
      '->begin_class can extend superclasses' );
}

done_testing;
