#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800;

class AClass {
   field $data :param;

   my method priv {
      "data<$data>";
   }

   method m { return priv($self); }
}

{
   my $obj = AClass->new( data => "value" );
   is( $obj->m, "data<value>", 'method can invoke lexical method from pad' );
}

done_testing;
