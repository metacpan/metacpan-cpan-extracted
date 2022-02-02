#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

{
   ok( !eval <<'EOPERL',
      has $field;
EOPERL
      'has outside class fails' );
   like( $@, qr/^Cannot 'has' outside of 'class' at /,
      'message from failure of has' );
}

# RT132337
{
   ok( !eval <<'EOPERL',
      class AClass { }
      has $field;
EOPERL
      'has after closed class block fails' );
   like( $@, qr/^Cannot 'has' outside of 'class' at /);
}

{
   ok( !eval <<'EOPERL',
      method m() { }
EOPERL
      'method outside class fails' );
   like( $@, qr/^Cannot 'method' outside of 'class' at /,
      'message from failure of method' );
}

done_testing;
