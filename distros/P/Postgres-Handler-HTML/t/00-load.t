#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Postgres::Handler::HTML' );
}

diag( "Testing Postgres::Handler::HTML $Postgres::Handler::HTML::VERSION, Perl $], $^X" );
