#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::Plurk' );
}

diag( "Testing Net::Plurk $Net::Plurk::VERSION, Perl $], $^X" );
