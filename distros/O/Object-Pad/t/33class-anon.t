#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800;

# anon class
{
   my $class = class {
      method message { "hello, world" }
   };

   my $obj = $class->new;

   ok( ref $obj, 'obj exists' );
   is( $obj->message, "hello, world", 'obj has message method' );
}

done_testing;
