#!perl -T

use Test::More tests => 1;

SKIP: {
    eval {
        require SWISH::API::Object;
    };
    if ($@) {
        skip "SWISH::API::Object required", 1;
    }
    use_ok( 'Search::OpenSearch::Engine::SWISH' );
    diag( "Testing Search::OpenSearch::Engine::SWISH $Search::OpenSearch::Engine::SWISH::VERSION, Perl $], $^X" );
}
