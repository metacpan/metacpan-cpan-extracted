#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;
use Object::Pad::ClassAttr::Struct;

class Example :Struct {
   has $x;
   has $y;
   has $z = undef;
}

{
   my $obj = Example->new( x => "the x", y => "the y" );
   is( $obj->x, "the x", 'obj has ->x from constructor' );
   is( $obj->y, "the y", 'obj has ->y from constructor' );

   $obj->z = "the z";
   is( $obj->z, "the z", 'obj has ->z from mutator' );
}

{
   ok( !defined eval { Example->new( x => 0, y => 0, w => "no" ) },
      'Example constructor does not like w param' );
   my $e = $@;
   # Recent versions of Object::Pad added quotes around the argument names
   like( $e, qr/^Unrecognised parameters for Example constructor: '?w'? /,
      'exception from Example constructor param failure' );
}

done_testing;
