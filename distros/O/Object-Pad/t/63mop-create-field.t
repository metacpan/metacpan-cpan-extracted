#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800 ':experimental(mop)';

class AClass {
   use Test2::V0 qw( :DEFAULT !field ); # don't import the field() check as its name will clash

   BEGIN {
      # Most of this test has to happen at BEGIN time before AClass gets
      # sealed
      my $classmeta = Object::Pad::MOP::Class->for_caller;

      my $fieldmeta = $classmeta->add_field( '$field',
         default => 100,
         param   => "field",
      );

      is( $fieldmeta->name, "\$field", '$fieldmeta->name' );

      like( dies { $classmeta->add_field( undef ) },
         qr/^fieldname must not be undefined or empty /,
         'Failure from ->add_field undef' );
      like( dies { $classmeta->add_field( "" ) },
         qr/^fieldname must not be undefined or empty /,
         'Failure from ->add_field on empty string' );

      like( dies { $classmeta->add_field( "foo" ) },
         qr/^fieldname must begin with a sigil /,
         'Failure from ->add_field without sigil' );

      like( dies { $classmeta->add_field( '$field' ) },
         qr/^Cannot add another field named \$field /,
         'Failure from ->add_field duplicate' );

      ok( *field = eval( 'method :lvalue { $field }' ),
         'Can compile method with lexical $field' );

      my $anonfield = $classmeta->add_field( '$' );
      *anonfield = sub :lvalue { $anonfield->value( shift ) };

      ok( !dies { $classmeta->add_field( '$' ) },
         'Can add a second anonymous field' );

      {
         '$magic' =~ m/^(.*)$/;
         my $fieldmeta = $classmeta->add_field( $1 );
         'different' =~ m/^(.*)$/;
         is( $fieldmeta->name, '$magic', '->add_field captures FETCH magic' );
      }

      $classmeta->add_field( '$field_with_accessors',
         reader => "get_swa",
         writer => "set_swa",
      );
   }
}

{
   my $obj = AClass->new;
   is( $obj->field, 100, '->field default value' );

   $obj->field = 10;
   is( $obj->field, 10, '->field accessor works' );

   $obj->anonfield = 20;
   is( $obj->anonfield, 20, '->anonfield accessor works' );

   $obj->set_swa( 30 );
   is( $obj->get_swa, 30, '->get_swa sees value to ->set_swa' );
}

# param name to constructor
{
   my $obj = AClass->new( field => 50 );
   is( $obj->field, 50, 'field was initialised from named param' );
}

done_testing;
