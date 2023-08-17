#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Object::Pad;
use Object::Pad::ClassAttr::Struct;

class Example :Struct {
   field $x;
   field $y;
   field $z = undef;
}

# Check that the ->new_values method works
{
   my $obj = Example->new_values( 10, 20, 30 );
   is( $obj->x, 10, 'obj has ->x from positional constructor' );
   is( $obj->y, 20, 'obj has ->y from positional constructor' );
   is( $obj->z, 30, 'obj has ->z from positional constructor' );
}

{
   ok( !defined eval { Example->new_values( 40 ) },
      'Positional constructor fails with insufficient values' );
   like( $@, qr/^Usage: Example->new_values\(\$x, \$y, \$z\) at /,
      'Exception message from failure of positional constructor' );
}

done_testing;
