#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Object::Pad;

class Animal {
   has $legs;
   method legs { $legs };

   method BUILDALL {
      ( $legs ) = @_;
   }
}

class Spider extends Animal {
   method BUILDALL {
      $self->SUPER::BUILDALL( 8 );
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

done_testing;
