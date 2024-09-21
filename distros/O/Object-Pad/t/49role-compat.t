#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800;

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
   isa_ok( $obj, [ "AClass" ], '$obj' );

   is( $obj->one, 1, 'AClass has a ->one method' );
   is( $obj->redir, 2, 'AClass has a ->redir method' );
}

# RT152793
{
   role RT152793 :compat(invokable) {
      method f { return 42; }
   }

   undef &RT152793::f;
   pass( 'Did not crash when deleting method of invokable role (RT152793)' );
}

done_testing;
