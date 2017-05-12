#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'TVDB::API' );
}

diag( "Testing TVDB::API $TVDB::API::VERSION, Perl $], $^X" );
