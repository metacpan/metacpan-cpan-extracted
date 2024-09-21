#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800 ':experimental(adjust_params)';

{
   ok( !eval <<'EOPERL',
      class AClass {
         field $x :param(foo);
         field $y :param(foo);
      }
EOPERL
      'Clashing :param names fails' );
   like( $@, qr/^Already have a named constructor parameter called 'foo' at /,
      'message from clashing :param names' );
}

{
   ok( !eval <<'EOPERL',
      class BClass {
         field $x :param(foo);
         ADJUST :params ( :$foo ) { }
      }
EOPERL
      'Clashing :param/ADJUST names fails' );
   like( $@, qr/^Already have a named constructor parameter called 'foo' at /,
      'message from clashing :param/ADJUST names' );
}

{
   ok( !eval <<'EOPERL',
      class CClass {
         ADJUST :params ( :$foo ) { }
         field $x :param(foo);
      }
EOPERL
      'Clashing ADJUST/:param names fails' );
   like( $@, qr/^Already have a named constructor parameter called 'foo' at /,
      'message from clashing ADJUST/:param names' );
}

done_testing;
