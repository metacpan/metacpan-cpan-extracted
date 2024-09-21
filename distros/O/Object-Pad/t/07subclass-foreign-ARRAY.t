#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800;

package Base::Class {
   sub new {
      my $class = shift;
      my ( $ok ) = @_;
      ::is( $ok, "ok", '@_ to Base::Class::new' );
      ::is( scalar @_, 1, 'scalar @_ to Base::Class::new' );

      return bless [ 123 ], $class;
   }

   sub fields {
      my $self = shift;
      return "base_field=$self->[0]"
   }
}

class Derived::Class {
   inherit Base::Class;

   field $derived_field = 456;

   BUILD {
      my @args = @_;
      ::is( \@args, [ "ok" ], '@_ to Derived::Class::BUILD' );
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
   use Data::Dumper;

   local $Data::Dumper::Sortkeys = 1;

   is( Dumper($obj) =~ s/\s+//gr,
      q($VAR1=bless([123],'Derived::Class');),
      'Dumper($obj) of Object::Pad-extended blessed ARRAY class' );
}

done_testing;
