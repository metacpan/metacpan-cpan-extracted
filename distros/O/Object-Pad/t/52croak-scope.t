#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

{
   ok( !eval <<'EOPERL',
      field $field;
EOPERL
      'field outside class fails' );
   like( $@, qr/^Cannot 'field' outside of 'class' at /,
      'message from failure of field' );
}

# RT132337
{
   ok( !eval <<'EOPERL',
      class AClass { }
      field $field;
EOPERL
      'field after closed class block fails' );
   like( $@, qr/^Cannot 'field' outside of 'class' at /);
}

{
   ok( !eval <<'EOPERL',
      method m() { }
EOPERL
      'method outside class fails' );
   like( $@, qr/^Cannot 'method' outside of 'class' at /,
      'message from failure of method' );
}

{
   ok( !eval <<'EOPERL',
      class BClass {
         my $c = __CLASS__;
      }
EOPERL
      '__CLASS__ outside method fails' );
   like( $@, qr/^Cannot use __CLASS__ outside of a /,
      'message from failure of __CLASS__' );
}

done_testing;
