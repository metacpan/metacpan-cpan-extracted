#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800 ':experimental( mop custom_field_attr )';

my $n;
Object::Pad::MOP::FieldAttr->register( SomeAttr =>
   permit_hintkey => "t/SomeAttr",
   must_value => 1,
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

   is( [ $fieldmeta->get_attribute_values( "SomeAttr" ) ], [ "result-1", "result-2" ],
      'can get multiple values' );
}

like( defined eval <<'EOPERL' ? undef : $@,
   BEGIN { $^H{"t/SomeAttr"}++ }
   class Test2 {
      field $x :SomeAttr;
   }
EOPERL
   qr/^Attribute :SomeAttr requires a value at /,
   'field attribute that requires a value complains when missing one' );

# custom attributes can be applied via MOP
{
   my $classmeta = Object::Pad::MOP::Class->create_class( "WithAttrMOP" );

   BEGIN { $^H{"t/SomeAttr"}++ }
   my $fieldmeta = $classmeta->add_field( '$field',
      attributes => [
         "SomeAttr" => "the value",
      ],
   );

   ok( $fieldmeta->has_attribute( "SomeAttr" ), 'MOP-added $field has :SomeAttr' );
   is( $fieldmeta->get_attribute_value( "SomeAttr" ), "result-3", 'stored value for :SomeAttr' );
}

done_testing;
