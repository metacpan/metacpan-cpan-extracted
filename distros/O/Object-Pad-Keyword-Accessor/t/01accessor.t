#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;
use Object::Pad::Keyword::Accessor;

my %callcount;

class Test1 {
   field $value :reader :writer;

   accessor x {
      get {
         $callcount{get}++;
         return $value;
      }
      set ($new) {
         $callcount{set}++;
         $value = $new;
      }
   }
}

my $obj = Test1->new;

# get
{
   $obj->set_value( "the value" );
   is( $obj->x, "the value", 'read access returns value' );
   ok( $callcount{get}, 'get {} was invoked' );
}

# set
{
   $obj->x = "new value";
   is( $obj->value, "new value", 'write access wrote value' );
   ok( $callcount{set}, 'set {} was invoked' );
}

done_testing;
