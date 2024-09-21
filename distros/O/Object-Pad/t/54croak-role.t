#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800;

{
   role ARole { method m {} }

   my $warnings;
   $SIG{__WARN__} = sub { $warnings .= join "", @_ };

   like( dies { ARole->new },
      qr/^Cannot directly construct an instance of role 'ARole' /,
      'failure from directly create a role instance' );

   ok( !eval <<'EOPERL',
      class AClass { apply ARole; method m {} }
EOPERL
      'class with clashing method name fails' );
   like( $@, qr/^Method 'm' clashes with the one provided by role ARole /,
      'message from failure of clashing method' );

   ok( !eval { ( bless {}, "ARole" )->m() },
      'direct invoke on role method fails' );
   like( $@, qr/^Cannot invoke a role method directly /,
      'message from failure to directly invoke role method' );
}

{
   role BRole { method bmeth; }

   ok( !eval <<'EOPERL',
      class BClass { apply BRole; }
EOPERL
      'class with missing required method fails' );
   like( $@, qr/^Class BClass does not provide a required method named 'bmeth' /,
      'message from failure of missing method' );
}

{
   ok( !eval <<'EOPERL',
      role CRole :compat(invokable) { field $field; }
EOPERL
      'invokable role with field fails' );
   like( $@, qr/^Cannot add field data to an invokable role /,
      'message from failure of invokable role with field' );
}

done_testing;
