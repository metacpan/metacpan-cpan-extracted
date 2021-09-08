#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

class Animal 1.23 {
   has $legs;
   method legs { $legs };

   BUILD {
      ( $legs ) = @_;
   }
}

is( $Animal::VERSION, 1.23, 'Versioned class has $VERSION' );

class Spider 4.56 isa Animal {
   sub BUILDARGS {
      my $self = shift;
      return $self->SUPER::BUILDARGS( 8 );
   }

   method describe {
      "An animal with " . $self->legs . " legs";
   }
}

is( $Spider::VERSION, 4.56, 'Versioned subclass has $VERSION' );

{
   my $spider = Spider->new;
   is( $spider->describe, "An animal with 8 legs",
      'Subclassed instances work' );
}

{
   ok( !eval <<'EOPERL',
      class Antelope isa Animal 2.34;
EOPERL
      'isa insufficient version fails' );
   like( $@, qr/^Animal version 2.34 required--this is only version 1.23 /,
      'message from insufficient version' );
}

# Extend before base class is sealed (RT133190)
{
   class BaseClass {
      has $_aslot;

      class SubClass isa BaseClass {
         method one { 1 }
      }
   }

   pass( 'Did not SEGV while compiling inner derived class' );
   is( SubClass->new->one, 1, 'Inner derived subclass instances can be constructed' );
}

# Make sure that ADJUSTPARAMS still works via trivial subclasses
{
   my $param;
   class WithAdjustParams {
      ADJUSTPARAMS {
         my ( $href ) = @_;
         $param = delete $href->{param};
      }
   }

   class TrivialSubclass isa WithAdjustParams {}

   TrivialSubclass->new( param => "value" );
   is( $param, "value", 'ADJUSTPARAMS still invoked on superclass' );
}

done_testing;
