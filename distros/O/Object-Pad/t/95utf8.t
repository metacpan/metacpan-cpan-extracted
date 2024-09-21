#!/usr/bin/perl

use v5.18;
use warnings;
use utf8;

BEGIN { binmode STDOUT, ":encoding(UTF-8)" }

use Test2::V0;

use Object::Pad 0.800 ':experimental(mop)';

# A bunch of test cases with non-ASCII, non-Latin1. Esperanto is good for that
# as the accented characters are not in Latin1.

my $manĝis;

class Sandviĉon {
   method manĝu { $manĝis++ }

   field $tranĉaĵoj :param :reader :writer = undef;
}

my $s = Sandviĉon->new;
isa_ok( $s, [ "Sandviĉon" ], '$s' );

my $classmeta = Object::Pad::MOP::Class->for_class( "Sandviĉon" );
ok( $classmeta, 'Can obtain classmeta for UTF-8 class name' );
is( $classmeta->name, "Sandviĉon", '$classmeta->name' );

# methods
{
   $s->manĝu;
   ok( $manĝis, 'UTF-8 method name works' );

   my $methodmeta = $classmeta->get_own_method( "manĝu" );
   ok( $methodmeta, 'Can obtain methodmeta for UTF-8 method name' );
   is( $methodmeta->name, "manĝu", '$methodmeta->name' );
}

# fields
{
   # accessors
   $s->set_tranĉaĵoj( 3 );
   is( $s->tranĉaĵoj, 3, 'Can obtain value from field via accessor' );

   my $fieldmeta = $classmeta->get_field( '$tranĉaĵoj' );
   ok( $fieldmeta, 'Can obtain fieldmeta for UTF-8 field name' );
   is( $fieldmeta->name, '$tranĉaĵoj', '$fieldmeta->name' );

   # params
   is( Sandviĉon->new( tranĉaĵoj => 2 )->tranĉaĵoj, 2,
      'Can construct with UTF-8 param' );
}

done_testing;
