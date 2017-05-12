#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Search::OpenSearch::Federated' ) || print "Bail out!\n";
}

diag( "Testing Search::OpenSearch::Federated $Search::OpenSearch::Federated::VERSION, Perl $], $^X" );
