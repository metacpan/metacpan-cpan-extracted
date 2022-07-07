#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad ':experimental( mop custom_field_attr )';

my $n;
Object::Pad::MOP::FieldAttr->register( SomeAttr =>
   permit_hintkey => "t/SomeAttr",
   apply => sub {
      my ( $fieldmeta, $value ) = @_;

      ::is( $value, "the value", '$value passed to apply callback' );

      return "result-" . ++$n;
   },
);

ok(
   defined eval <<'EOPERL',
      BEGIN { $^H{"t/SomeAttr"}++ }
      class MyClass {
         field $x;
         field $y :SomeAttr(the value) :SomeAttr(the value);
      }
EOPERL
   'class using field attribute can be compiled' ) or
      diag( "Failure was $@" );

{
   # SomeAttr needs to be lexically in scope for lookups to find it
   BEGIN { $^H{"t/SomeAttr"}++ }

   my $classmeta = Object::Pad::MOP::Class->for_class( "MyClass" );
   my $fieldmeta = $classmeta->get_field( '$y' );

   ok( $fieldmeta->has_attribute( "SomeAttr" ), '$y field has :SomeAttr' );
   is( $fieldmeta->get_attribute_value( "SomeAttr" ), "result-1", 'stored value for :SomeAttr' );

   is_deeply( [ $fieldmeta->get_attribute_values( "SomeAttr" ) ], [ "result-1", "result-2" ],
      'can get multiple values' );
}

done_testing;
