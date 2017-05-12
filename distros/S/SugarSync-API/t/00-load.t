#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'SugarSync::API' );
}

diag( "Testing SugarSync::API $SugarSync::API::VERSION, Perl $], $^X" );
