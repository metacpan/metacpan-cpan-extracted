#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Search::Query::Dialect::Lucy' );
}

diag( "Testing Search::Query::Dialect::Lucy $Search::Query::Dialect::Lucy::VERSION, Perl $], $^X" );
