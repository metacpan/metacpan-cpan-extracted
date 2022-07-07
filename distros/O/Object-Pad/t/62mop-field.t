#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Fatal;

use Object::Pad ':experimental(mop)';

class Example {
   has $field :mutator :param(initial_field) = undef;
}

my $classmeta = Object::Pad::MOP::Class->for_class( "Example" );

my $fieldmeta = $classmeta->get_field( '$field' );

is( $fieldmeta->name, "\$field", '$fieldmeta->name' );
is( $fieldmeta->sigil, "\$", '$fieldmeta->sigil' );
is( $fieldmeta->class->name, "Example", '$fieldmeta->class gives class' );

ok( $fieldmeta->has_attribute( "mutator" ), '$fieldmeta has "mutator" attribute' );
is( $fieldmeta->get_attribute_value( "mutator" ), "field",
   'value of $fieldmeta "mutator" attribute' );

is( $fieldmeta->get_attribute_value( "param" ), "initial_field",
   'value of $fieldmeta "param" attribute' );

is_deeply( [ $classmeta->fields ], [ $fieldmeta ],
   '$classmeta->fields' );

# $fieldmeta->value as accessor
{
   my $obj = Example->new;
   $obj->field = "the value";

   is( $fieldmeta->value( $obj ), "the value",
      '$fieldmeta->value as accessor' );
}

# $fieldmeta->value as mutator
{
   my $obj = Example->new;

   $fieldmeta->value( $obj ) = "a new value";

   is( $obj->field, "a new value",
      '$obj->field after $fieldmeta->value as mutator' );
}

# fieldmeta on roles (RT138927)
{
   role ARole {
      has $data = 42;
   }

   my $fieldmeta = Object::Pad::MOP::Class->for_class( 'ARole' )->get_field( '$data' );
   is( $fieldmeta->name, '$data', '$fieldmeta->name for field of role' );

   class AClass :does(ARole) {
      has $data = 21;
   }

   my $obja = AClass->new;
   is( $fieldmeta->value( $obja ), 42,
      '$fieldmeta->value as accessor on role instance fetches correct field' );

   class BClass :isa(AClass) {
      has $data = 63;
   }

   my $objb = BClass->new;
   is( $fieldmeta->value( $objb ), 42,
      '$fieldmeta->value as accessor on role instance subclass fetches correct field' );
}

# RT136869
{
   class A {
      field @arr;
      BUILD { @arr = (1,2,3) }
      method m { @arr }
   }
   role R {
      field $data :param;
   }
   class B :isa(A) :does(R) {}

   is_deeply( [ B->new( data => 456 )->m ], [ 1, 2, 3 ],
      'Role params are embedded correctly' );
}

# Forbid writing to non-scalar fields via ->value
{
   class List {
      field @values :reader;
   }

   my $list = List->new;

   my $arrayfieldmeta = Object::Pad::MOP::Class->for_class( "List" )
      ->get_field( '@values' );

   like( exception { no warnings; $arrayfieldmeta->value( $list ) = [] },
      qr/^Modification of a read-only value attempted at /,
      'Attempt to set value of list field fails' );

   my $e;
   ok( !defined( $e = exception { @{ $arrayfieldmeta->value( $list ) } = (1,2,3) } ),
      '->value accessor still works fine' ) or
      diag( "Exception was $e" );
   is_deeply( [ $list->values ], [ 1,2,3 ], '$list->values after modification via fieldmeta' );
}

done_testing;
