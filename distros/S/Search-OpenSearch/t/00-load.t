use Test::More tests => 3;

BEGIN {
    use_ok( 'Search::OpenSearch' );
}

diag( "Testing Search::OpenSearch $Search::OpenSearch::VERSION, Perl $], $^X" );

use_ok('Search::OpenSearch::Engine');
use_ok('Search::OpenSearch::Response');

