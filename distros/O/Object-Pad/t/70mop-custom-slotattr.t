#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

Object::Pad::MOP::SlotAttr->register( SomeAttr =>
   permit_hintkey => "t/SomeAttr",
   apply => sub {
      my ( $slotmeta, $value ) = @_;

      ::is( $value, "the value", '$value passed to apply callback' );

      return "stored result";
   },
);

ok(
   defined eval <<'EOPERL',
      BEGIN { $^H{"t/SomeAttr"}++ }
      class MyClass {
         has $x;
         has $y :SomeAttr(the value);
      }
EOPERL
   'class using slot attribute can be compiled' ) or
      diag( "Failure was $@" );

{
   # SomeAttr needs to be lexically in scope for lookups to find it
   BEGIN { $^H{"t/SomeAttr"}++ }

   my $classmeta = Object::Pad::MOP::Class->for_class( "MyClass" );
   my $slotmeta = $classmeta->get_slot( '$y' );

   ok( $slotmeta->has_attribute( "SomeAttr" ), '$y slot has :SomeAttr' );
   is( $slotmeta->get_attribute_value( "SomeAttr" ), "stored result", 'stored value for :SomeAttr' );
}

done_testing;
