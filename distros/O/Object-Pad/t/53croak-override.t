#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800;

{
   ok( !eval <<'EOPERL',
   class Example {
      method thing :override { }
   }
EOPERL
      'method :override without matching superclass method fails' );
   like( $@, qr/^Superclass does not have a method named 'thing'/,
      'message from failure of :override' );
}

done_testing;
