#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::SMS::TMobile::UK' );
}

diag( "Testing Net::SMS::TMobile::UK $Net::SMS::TMobile::UK::VERSION, Perl $], $^X" );
