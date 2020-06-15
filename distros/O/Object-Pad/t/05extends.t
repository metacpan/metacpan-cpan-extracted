#!/usr/bin/perl

use strict;
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

class Spider extends Animal {
   sub BUILDARGS {
      my $self = shift;
      return $self->SUPER::BUILDARGS( 8 );
   }

   method describe {
      "An animal with " . $self->legs . " legs";
   }
}

{
   my $spider = Spider->new;
   is( $spider->describe, "An animal with 8 legs",
      'Subclassed instances work' );
}

{
   ok( !eval <<'EOPERL',
      class Antelope extends Animal 2.34;
EOPERL
      'extends insufficient version fails' );
   like( $@, qr/^Animal version 2.34 required--this is only version 1.23 /,
      'message from insufficient version' );
}

done_testing;
