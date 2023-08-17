#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Object::Pad;
use Object::Pad::FieldAttr::Checked;

{
   local $SIG{__WARN__} = sub {};

   ok( eval( 'class T1 { field $x :Checked(1 2 3 4); }' ) ? undef : $@,
      # TODO: Assert on the message
      'Invalid code in :Checked fails to compile' );
}

like( eval( 'class T2 { field $x :Checked(NotAPackage); }' ) ? undef : $@,
   qr/^Expected the checker expression to yield an object reference or package name at /,
   'Failure from invalid package name' );

package NotAChecker { sub foo {} }

like( eval( 'class T3 { field $x :Checked(NotAChecker); }' ) ? undef : $@,
   qr/^Expected that the checker expression can ->check at /,
   'Failure from invalid checker package' );

done_testing;
