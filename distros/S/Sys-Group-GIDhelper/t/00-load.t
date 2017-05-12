#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Sys::Group::GIDhelper' );
}

diag( "Testing Sys::Group::GIDhelper $Sys::Group::GIDhelper::VERSION, Perl $], $^X" );
