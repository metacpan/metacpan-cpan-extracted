#!/usr/bin/env perl
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use JSON;

use constant HAS_LEAKTRACE => eval { require Test::LeakTrace };
use Test::More HAS_LEAKTRACE
    ? ( tests => 21 )
    : ( skip_all => 'require Test::LeakTrace' );
use Test::LeakTrace;

SKIP: {

    my $index_path = $ENV{OPENSEARCH_INDEX};
    if ( !defined $index_path or !-d $index_path ) {
        diag("set OPENSEARCH_INDEX to valid path to test Plack with Lucy");
        skip "set OPENSEARCH_INDEX to valid path to test Plack with Lucy", 21;
    }
    eval "use Plack::Test";
    if ($@) {
        skip "Plack::Test not available", 21;
    }
    eval "use Search::OpenSearch::Engine::Lucy";
    if ($@) {
        skip "Search::OpenSearch::Engine::Lucy not available", 21;
    }

    require Search::OpenSearch::Server::Plack;
    require HTTP::Request;

    leaks_cmp_ok {
        my $app = Search::OpenSearch::Server::Plack->new(
            engine_config => {
                type  => 'Lucy',
                index => [$index_path],
                facets =>
                    { names => [qw( topics people places orgs author )], },
                fields => [qw( topics people places orgs author )],
            }
        );
        test_psgi(
            app    => $app,
            client => sub {
                my $cb = shift;
                my $req
                    = HTTP::Request->new( GET => 'http://localhost/?q=test' );
                my $res = $cb->($req);
                ok( my $results = decode_json( $res->content ),
                    "decode_json response" );
                is( $results->{query}, "test", "query param returned" );
                cmp_ok( $results->{total}, '>', 1, "more than one hit" );
                ok( exists $results->{search_time},
                    "search_time key exists" );
                is( $results->{title}, qq/OpenSearch Results/, "got title" );
            }
        );
    }
    '<', 1, "no mem leaks";

}
