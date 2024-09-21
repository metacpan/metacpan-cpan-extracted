#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800 ':experimental(inherit_field)';

class Class1 {
   field $data :inheritable;
   method data { $data }

   ADJUST {
      $data = "base data"
   }
}

class Class2 {
   inherit Class1;

   field $data;
   method data { $data }

   ADJUST {
      $data = "derived data";
   }
}

{
   my $c = Class2->new;
   is( $c->data, "derived data",
      'subclass wins methods' );
   is( $c->Class1::data, "base data",
      'base class still accessible' );
}

class Class3 {
   inherit Class1 qw( $data );

   method data3 { return $data }
}

{
   my $c = Class3->new;
   is( $c->data3, "base data",
      'subclass can inherit base field' );
}

done_testing;
