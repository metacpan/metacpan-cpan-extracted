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

extended sub g_as_package (:$y :Checked('Numerical')) { }

{
   ok( lives { g_as_package( y => 0 ) },
      'f_as_package with number OK' ) or
      diag( "Failed $@" );

   like( dies { g_as_package( y => "zero" ) },
      qr/^Named parameter :\$y requires a value satisfying Numerical /,
      'f_as_package with string throws' );
}

extended sub g_with_default (:$y :Checked('Numerical') = 20) { return $y }

{
   is( g_with_default(),          20, 'default applies' );
   is( g_with_default( y => 30 ), 30, 'default overridable' );
}

done_testing;
