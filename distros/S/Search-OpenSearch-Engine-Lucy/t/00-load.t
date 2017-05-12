#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Search::OpenSearch::Engine::Lucy' );
}

diag( "Testing Search::OpenSearch::Engine::Lucy $Search::OpenSearch::Engine::Lucy::VERSION, Perl $], $^X" );
