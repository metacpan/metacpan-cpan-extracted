#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'RT::Extension::UserDetails' );
}

diag( "Testing RT::Extension::UserDetails $RT::Extension::UserDetails::VERSION, Perl $], $^X" );
