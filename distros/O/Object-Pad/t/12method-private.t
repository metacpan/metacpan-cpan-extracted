#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

class AClass {
   field $data :param;

   my $priv = method {
      "data<$data>";
   };

   method m { return $self->$priv }
}

{
   my $obj = AClass->new( data => "value" );
   is( $obj->m, "data<value>", 'method can invoke captured method ref' );
}

class BClass {
   field $data :param;

   method $priv {
      "data<$data>";
   }

   method m {
      return $self->$priv
   }
}

{
   my $obj = BClass->new( data => "second" );
   is( $obj->m, "data<second>", 'method can invoke private lexical method' );
}

done_testing;
