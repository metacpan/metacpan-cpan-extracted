#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'SQL::QueryBuilder::Pretty' );
}

diag( "Testing SQL::QueryBuilder::Pretty $SQL::QueryBuilder::Pretty::VERSION, Perl $], $^X" );
