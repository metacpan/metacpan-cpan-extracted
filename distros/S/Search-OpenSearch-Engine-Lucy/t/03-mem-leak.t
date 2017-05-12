#!/usr/bin/env perl
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use JSON;

use constant HAS_LEAKTRACE => eval { require Test::LeakTrace };
use Test::More HAS_LEAKTRACE
    ? ( tests => 1 )
    : ( skip_all => 'require Test::LeakTrace' );
use Test::LeakTrace;
use Search::OpenSearch;
use Search::OpenSearch::Engine::Lucy;

SKIP: {

    my $index_path = $ENV{OPENSEARCH_INDEX};
    if ( !defined $index_path or !-d $index_path ) {
        diag("set OPENSEARCH_INDEX to valid path to test Plack with Lucy");
        skip "set OPENSEARCH_INDEX to valid path to test Plack with Lucy", 1;
    }
    if ( !defined $ENV{TEST_LEAKS}) {
        diag("set TEST_LEAKS to test leaks");
        skip "set TEST_LEAKS=1 to test leaks", 1;
    }

    leaks_cmp_ok {
        my $engine = Search::OpenSearch->engine(
            type   => 'Lucy',
            index  => [$index_path],
            facets => { names => [qw( topics people places orgs author )], },
            fields => [qw( topics people places orgs author )],
        );
        my $response = $engine->search(
            q => 'test',
            t => 'JSON',
            f => 0,
            r => 0,
        );

        #diag($response);
        my $perl = decode_json("$response");

        #diag( dump $perl );

    }
    '<=', 24, "run engine";

}
