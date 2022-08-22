#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad ':experimental( mop )';
use Object::Pad::MetaFunctions qw(
   metaclass
   deconstruct_object
   ref_field
   get_field
);

class Point {
   has $x :param = 0;
   has $y :param = 0;
}

is( metaclass( Point->new ), Object::Pad::MOP::Class->for_class( "Point" ),
   'metaclass() returns Point metaclass' );

class AllFieldTypes {
   has $s = "scalar";
   has @a = ( "array", "values" );
   has %h = ( key => "value" );
}

is_deeply( [ deconstruct_object( AllFieldTypes->new ) ],
   [ 'AllFieldTypes',
     'AllFieldTypes.$s' => "scalar",
     'AllFieldTypes.@a' => [ "array", "values" ],
     'AllFieldTypes.%h' => { key => "value" } ],
  'deconstruct_object on AllFieldTypes' );

class AClass {
   has $a = "a";
}
role BRole {
   has $b = "b";
}
class CClass :isa(AClass) :does(BRole) {
   has $c = "c";
}

is_deeply( [ deconstruct_object( CClass->new ) ],
   [ 'CClass',
     'CClass.$c' => "c",
     'BRole.$b'  => "b",
     'AClass.$a' => "a", ],
   'deconstruct_object on CClass' );

# ref_field
{
   my $obj = AllFieldTypes->new;

   is_deeply( ref_field( 'AllFieldTypes.$s', $obj ), \"scalar",
      'ref_field on scalar field' );
   is_deeply( ref_field( 'AllFieldTypes.@a', $obj ), [ "array", "values" ],
      'ref_field on array field' );
   is_deeply( ref_field( 'AllFieldTypes.%h', $obj ), { key => "value" },
      'ref_field on hash field' );

   is_deeply( ref_field( '$s', $obj ), \"scalar",
      'ref_field short name' );

   is_deeply( ref_field( 'BRole.$b', CClass->new ), \"b",
      'ref_field can search roles' );
}

# get_field
{
   my $obj = AllFieldTypes->new;

   is( get_field( '$s', $obj ), "scalar",
      'get_field on scalar field' );

   is_deeply( [ get_field( '@a', $obj ) ], [ "array", "values" ],
      'get_field on array field' );
   is( scalar get_field( '@a', $obj ), 2,
      'scalar get_field on array field' );

   # Before perl 5.26 hashes in scalar context would yield a string like
   # 'KEYCOUNT/BUCKETCOUNT'. We can't be sure what the bucket count will be
   # here
   my $scalar_hash_re = ( $] < 5.026 ) ? qr(^1/\d+$) : qr(^1$);

   is_deeply( { get_field( '%h', $obj ) }, { key => "value" },
      'get_field on hash field' );
   like( scalar get_field( '%h', $obj ), $scalar_hash_re,
      'scalar get_field on hash field' );
}

done_testing;
