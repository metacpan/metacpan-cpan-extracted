#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Fatal;

use Object::Pad;

package Base::Class {
   sub new {
      my $class = shift;
      my ( $ok ) = @_;
      Test::More::is( $ok, "ok", '@_ to Base::Class::new' );
      Test::More::is( scalar @_, 1, 'scalar @_ to Base::Class::new' );

      return bless [ 123 ], $class;
   }

   sub fields {
      my $self = shift;
      return "base_field=$self->[0]"
   }
}

class Derived::Class isa Base::Class {
   has $derived_field = 456;

   BUILD {
      my @args = @_;
      Test::More::is_deeply( \@args, [ "ok" ], '@_ to Derived::Class::BUILD' );
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
      q(bless([123], "Derived::Class")),
      'pp($obj) of Object::Pad-extended blessed ARRAY class' );
}

done_testing;
