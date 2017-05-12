#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Search::Query::Dialect::KSx' );
}

diag( "Testing Search::Query::Dialect::KSx $Search::Query::Dialect::KSx::VERSION, Perl $], $^X" );
