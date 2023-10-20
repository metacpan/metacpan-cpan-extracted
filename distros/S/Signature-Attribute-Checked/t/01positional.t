#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use Sublike::Extended;
use Signature::Attribute::Checked;

use experimental 'signatures';

package Numerical {
   sub check { return $_[1] =~ m/^\d+(?:\.\d+)?$/ }
}

extended sub f_as_package ($x :Checked('Numerical')) { return $x + 1 }

{
   ok( lives { f_as_package( 0 ) },
      'f_as_package with number OK' );
   is( f_as_package( 10 ), 11,
      'f_as_package sees correct param value' );

   like( dies { f_as_package( "zero" ) },
      qr/^Parameter \$x requires a value satisfying :Checked\('Numerical'\) /,
      'f_as_package with string throws' );
}

package ArrayRefChecker {
   sub check { return ref($_[1]) eq "ARRAY" }
}
sub ArrayRef { return bless {}, "ArrayRefChecker" }

extended sub f_as_object ($x :Checked(ArrayRef)) { }

{
   ok( lives { f_as_object( [ 1, 2, 3 ] ) },
      'f_as_object with arrayref OK' );

   like( dies { f_as_object( "1,2,3" ) },
      qr/^Parameter \$x requires a value satisfying :Checked\(ArrayRef\) /,
      'f_as_object with string throws' );
}

extended sub f_with_default ($x :Checked('Numerical') = 20) { return $x }

{
   is( f_with_default(),     20, 'default applies' );
   is( f_with_default( 30 ), 30, 'default overridable' );
}

extended sub add($x :Checked('Numerical'), $y :Checked('Numerical')) { return $x + $y }

{
   is( add( 12, 34 ), 46, 'multiple parameters' );
}

done_testing;
