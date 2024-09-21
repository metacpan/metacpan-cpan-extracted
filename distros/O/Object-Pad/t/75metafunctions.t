#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800 ':experimental(mop inherit_field)';
use Object::Pad::MetaFunctions qw(
   metaclass
   deconstruct_object
   ref_field
   get_field
);

class Point {
   field $x :param = 0;
   field $y :param = 0;
}

is( metaclass( Point->new ), Object::Pad::MOP::Class->for_class( "Point" ),
   'metaclass() returns Point metaclass' );

class AllFieldTypes {
   field $s = "scalar";
   field @a = ( "array", "values" );
   field %h = ( key => "value" );
}

is( [ deconstruct_object( AllFieldTypes->new ) ],
   [ 'AllFieldTypes',
     'AllFieldTypes.$s' => "scalar",
     'AllFieldTypes.@a' => [ "array", "values" ],
     'AllFieldTypes.%h' => { key => "value" } ],
  'deconstruct_object on AllFieldTypes' );

class AClass {
   field $a = "a";
}
role BRole {
   field $b = "b";
}
class CClass {
   inherit AClass;
   apply BRole;

   field $c = "c";
}

is( [ deconstruct_object( CClass->new ) ],
   [ 'CClass',
     'CClass.$c' => "c",
     'BRole.$b'  => "b",
     'AClass.$a' => "a", ],
   'deconstruct_object on CClass' );

# Inherited fields don't deconstruct
{
   class DClass {
      field $x :inheritable;
   }
   class EClass {
      inherit DClass qw( $x );
      ADJUST { $x = 123; }
   }
   is( [ deconstruct_object( EClass->new ) ],
      [ 'EClass',
        'DClass.$x' => 123, ],
      'deconstruct_object does not dump inherited fields' );
}

# ref_field
{
   my $obj = AllFieldTypes->new;

   is( ref_field( 'AllFieldTypes.$s', $obj ), \"scalar",
      'ref_field on scalar field' );
   is( ref_field( 'AllFieldTypes.@a', $obj ), [ "array", "values" ],
      'ref_field on array field' );
   is( ref_field( 'AllFieldTypes.%h', $obj ), { key => "value" },
      'ref_field on hash field' );

   is( ref_field( '$s', $obj ), \"scalar",
      'ref_field short name' );

   is( ref_field( 'BRole.$b', CClass->new ), \"b",
      'ref_field can search roles' );
}

# get_field
{
   my $obj = AllFieldTypes->new;

   is( get_field( '$s', $obj ), "scalar",
      'get_field on scalar field' );

   is( [ get_field( '@a', $obj ) ], [ "array", "values" ],
      'get_field on array field' );
   is( scalar get_field( '@a', $obj ), 2,
      'scalar get_field on array field' );

   # Before perl 5.26 hashes in scalar context would yield a string like
   # 'KEYCOUNT/BUCKETCOUNT'. We can't be sure what the bucket count will be
   # here
   my $scalar_hash_re = ( $] < 5.026 ) ? qr(^1/\d+$) : qr(^1$);

   is( { get_field( '%h', $obj ) }, { key => "value" },
      'get_field on hash field' );
   like( scalar get_field( '%h', $obj ), $scalar_hash_re,
      'scalar get_field on hash field' );
}

done_testing;
