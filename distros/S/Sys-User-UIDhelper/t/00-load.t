#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Sys::User::UIDhelper' );
}

diag( "Testing Sys::User::UIDhelper $Sys::User::UIDhelper::VERSION, Perl $], $^X" );
