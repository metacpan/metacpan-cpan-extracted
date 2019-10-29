#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Object::Pad;

package Base::Class {
   sub new {
      return bless { base_field => 123 }, shift;
   }

   sub fields {
      my $self = shift;
      return "base_field=$self->{base_field}"
   }
}

class Derived::Class extends Base::Class {
   has $derived_field = 456;

   method fields {
      return $self->SUPER::fields . ",derived_field=$derived_field";
   }
}

{
   my $obj = Derived::Class->new;
   is( $obj->fields, "base_field=123,derived_field=456",
      '$obj->fields' );

   # We don't mind what the output here is but it should be well-behaved
   # and not crash the dumper
   use Data::Dump 'pp';

   is( pp($obj),
      q(bless({ "base_field" => 123, "Object::Pad/slots" => [456] }, "Derived::Class")),
      'pp($obj) of Object::Pad-extended foreign HASH class' );
}

done_testing;
