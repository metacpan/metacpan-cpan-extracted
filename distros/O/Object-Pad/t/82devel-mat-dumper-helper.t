#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;
BEGIN {
   eval { require Devel::MAT; Devel::MAT->VERSION( '0.49' ) } or
      plan skip_all => "No Devel::MAT version 0.49";

   require Devel::MAT::Dumper;
}

use Object::Pad 0.800;

class AClass
{
   field $afield :param :reader;
}

my $obj = AClass->new( afield => 123 );

( my $file = __FILE__ ) =~ s/\.t$/.pmat/;
Devel::MAT::Dumper::dump( $file );
END { unlink $file if -f $file }

my $pmat = Devel::MAT->load( $file );
my $df = $pmat->dumpfile;

# class/field/method representation
{
   my $classmeta = $pmat->find_symbol( "&AClass::META" )->constval->rv
      ->outref_named( "the Object::Pad class" )
      ->sv;

   ok( $classmeta, 'AClass has a classmeta' );
   isa_ok( $classmeta, [ "Devel::MAT::SV::C_STRUCT" ], '$classmeta' );

   is( $classmeta->desc, "C_STRUCT(Object::Pad/ClassMeta.class)", '$classmeta->desc' );

   is( $classmeta->field_named( "the name SV" )->pv, 'AClass', '$classmeta name SV' );

   # Field
   my @fieldmetas = $classmeta->field_named( "the fields AV" )->elems;
   is( scalar @fieldmetas, 1, '$classmeta has 1 fieldmeta' );

   my $fieldmeta = $fieldmetas[0];
   isa_ok( $fieldmeta, [ "Devel::MAT::SV::C_STRUCT" ], '$fieldmeta' );

   is( $fieldmeta->desc, "C_STRUCT(Object::Pad/FieldMeta)", '$fieldmeta->desc' );

   is( $fieldmeta->field_named( "the name SV" )->pv, '$afield', '$fieldmeta name SV' );
   is( $fieldmeta->field_named( "the class" ), $classmeta,      '$fieldmeta class' );

   # Method
   my @methodmetas = $classmeta->field_named( "the direct methods AV" )->elems;
   is( scalar @methodmetas, 1, '$classmeta has 1 methodmeta' );

   my $methodmeta = $methodmetas[0];
   isa_ok( $methodmeta, [ "Devel::MAT::SV::C_STRUCT" ], '$methodmeta' );

   is( $methodmeta->desc, "C_STRUCT(Object::Pad/MethodMeta)", '$methodmeta->desc' );

   is( $methodmeta->field_named( "the name SV" )->pv, 'afield', '$methodmeta name SV' );
   is( $methodmeta->field_named( "the class" ), $classmeta,     '$methodmeta class' );
}

done_testing;
