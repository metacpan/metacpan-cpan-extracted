#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Search::OpenSearch::Server' );
}

diag( "Testing Search::OpenSearch::Server $Search::OpenSearch::Server::VERSION, Perl $], $^X" );
