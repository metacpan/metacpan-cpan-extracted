#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Search::OpenSearch::Engine::KSx' );
}

diag( "Testing Search::OpenSearch::Engine::KSx $Search::OpenSearch::Engine::KSx::VERSION, Perl $], $^X" );
