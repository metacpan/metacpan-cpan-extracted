#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Search::OpenSearch::Engine::Xapian' );
}

diag( "Testing Search::OpenSearch::Engine::Xapian $Search::OpenSearch::Engine::Xapian::VERSION, Perl $], $^X" );
