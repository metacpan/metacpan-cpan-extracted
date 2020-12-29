#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

role ARole :compat(invokable) {
   method one { return 1 }

   method redir { return $self->two }
}

# A classical perl class
package AClass {
   use base 'ARole';

   sub new { bless [], shift }

   sub two { return 2 }
}

{
   my $obj = AClass->new;
   isa_ok( $obj, "AClass", '$obj' );

   is( $obj->one, 1, 'AClass has a ->one method' );
   is( $obj->redir, 2, 'AClass has a ->redir method' );
}

done_testing;
