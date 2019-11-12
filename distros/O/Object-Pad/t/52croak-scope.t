#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Object::Pad;

{
   ok( !eval <<'EOPERL',
      has $slot;
EOPERL
      'has outside class fails' );
   like( $@, qr/^Cannot 'has' outside of 'class' at /,
      'message from failure of has' );
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
