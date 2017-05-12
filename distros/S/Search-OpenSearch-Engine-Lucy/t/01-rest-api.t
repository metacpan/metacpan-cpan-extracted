#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 7;
use Data::Dump qw( dump );
use JSON;
use Search::OpenSearch::Engine::Lucy;

my $debug = $ENV{PERL_DEBUG} || 0;

SKIP: {

    my $index_path = $ENV{OPENSEARCH_INDEX};
    if ( !defined $index_path or !-d $index_path ) {
        diag("set OPENSEARCH_INDEX to valid path to test REST API");
        skip "set OPENSEARCH_INDEX to valid path to test REST API", 7;
    }

    my $engine = Search::OpenSearch::Engine::Lucy->new(
        index  => [$index_path],
        facets => { names => [qw( topics people places orgs author )], },
        fields => [qw( topics people places orgs author )],
    );

    my $resp;

    #dump( $engine->search( q => 'swishdocpath=foo/bar' ) );

    $resp = $engine->GET('foo/bar');
    $debug and dump($resp);
    is( $resp->{code}, 404, "GET == 404" );

    $resp = $engine->PUT(
        {   url     => 'foo/bar',
            content => '<doc><title>i am a test</title></doc>',
            type    => 'application/xml',
        }
    );
    $debug and dump($resp);
    is( $resp->{code}, 201, "PUT == 201" );

    $resp = $engine->GET('foo/bar');

    $debug and dump($resp);
    is( $resp->{code}, 200, "GET == 200" );

    $resp = $engine->POST(
        {   url     => 'foo/bar',
            content => '<doc><title>i am a POST test</title></doc>',
            type    => 'application/xml',
        }
    );

    $debug and dump($resp);
    is( $resp->{code}, 200, "POST == 200" );

    $resp = $engine->GET('foo/bar');
    $debug and dump($resp);
    is( $resp->{code}, 200, "GET == 200" );
    is( $resp->{doc}->{title}, "i am a POST test", "title updated" );

    $resp = $engine->DELETE('foo/bar');
    $debug and dump($resp);
    is( $resp->{code}, 200, "DELETE == 200" );
}
