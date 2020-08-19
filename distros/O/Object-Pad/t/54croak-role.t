#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Object::Pad;

{
   role ARole { method m {} }

   my $warnings;
   $SIG{__WARN__} = sub { $warnings .= join "", @_ };

   ok( !eval <<'EOPERL',
      class AClass implements ARole { method m {} }
EOPERL
      'class with clashing method name fails' );
   like( $@, qr/^Method 'm' clashes with the one provided by role ARole /,
      'message from failure of clashing method' );
}

{
   role BRole { requires bmeth; }

   ok( !eval <<'EOPERL',
      class BClass implements BRole { }
EOPERL
      'class with missing required method fails' );
   like( $@, qr/^Class BClass does not provide a required method named 'bmeth' /,
      'message from failure of missing method' );
}

done_testing;
