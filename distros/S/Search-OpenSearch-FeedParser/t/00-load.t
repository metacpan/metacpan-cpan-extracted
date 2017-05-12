#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Search::OpenSearch::Feed' ) || print "Bail out!\n";
}

diag( "Testing Search::OpenSearch::Feed $Search::OpenSearch::Feed::VERSION, Perl $], $^X" );
