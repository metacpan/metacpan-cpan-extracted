#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Object::Pad 0.800;
use Object::Pad::FieldAttr::Checked;

package IsAChecker { sub check {} }

{
   local $SIG{__WARN__} = sub {};

   ok( eval( q[class T1 { field $x :Checked(1 2 3 4); }] ) ? undef : $@,
      # TODO: Assert on the message
      'Invalid code in :Checked fails to compile' );

   like( eval( q[class T1b { field $x :Checked($undeclvar = undef; 'IsAChecker'); }] ) ? undef : $@,
      qr/^Global symbol "\$undeclvar\" requires explicit package name /,
      ':Checked inherits strict hints' );
}

like( eval( q[class T2 { field $x :Checked('NotAPackage'); }] ) ? undef : $@,
   qr/^Expected the checker expression to yield an object or code reference or package name; got NotAPackage instead at /,
   'Failure from invalid package name' );

package NotAChecker { sub foo {} }

like( eval( q[class T3 { field $x :Checked('NotAChecker'); }] ) ? undef : $@,
   qr/^Expected that the checker expression can ->check at /,
   'Failure from invalid checker package' );

done_testing;
