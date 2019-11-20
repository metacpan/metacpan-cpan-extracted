#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Object::Pad;

package Base::Class {
   sub new {
      my $class = shift;
      my ( $ok ) = @_;
      Test::More::is( $ok, "ok", '@_ to Base::Class::new' );
      Test::More::is( scalar @_, 1, 'scalar @_ to Base::Class::new' );

      return bless { base_field => 123 }, $class;
   }

   sub fields {
      my $self = shift;
      return "base_field=$self->{base_field}"
   }
}

class Derived::Class extends Base::Class {
   has $derived_field = 456;

   method BUILD($ok) {
      Test::More::is( $ok, "ok", '@_ to Derived::Class::BUILD' );
   }

   method fields {
      return $self->SUPER::fields . ",derived_field=$derived_field";
   }
}

{
   my $obj = Derived::Class->new( "ok" );
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
