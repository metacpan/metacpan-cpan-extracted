#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::xFTP' );
}

diag( "Testing Net::xFTP $Net::xFTP::VERSION, Perl $], $^X" );
