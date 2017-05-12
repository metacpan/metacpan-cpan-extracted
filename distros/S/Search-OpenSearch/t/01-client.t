#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 2;
use Data::Dump qw( dump );

if ( !$ENV{PLACK_TEST} ) {
    diag "set PLACK_TEST and make sure plack server is running";
}

SKIP:
{
    eval { require WWW::OpenSearch; };
    if ($@) {
        skip "WWW::OpenSearch required for client checks", 2;
    }
    if ( !$ENV{PLACK_TEST} ) {
        skip
            "set PLACK_TEST=1 and verify server is running on localhost:5000",
            2;
    }

    require WWW::OpenSearch::Url;
    my $os_url = WWW::OpenSearch::Url->new(
        template => "http://localhost:5000/search?t=XML&q=test",
        method   => 'GET',
        ns       => 'http://a9.com/-/spec/opensearch/1.1/',     #'opensearch',
    );
    my $request = WWW::OpenSearch::Request->new($os_url);
    my $agent   = WWW::OpenSearch::Agent->new();

    ok( my $response = $agent->request($request), "get request" );

    #dump( $response );
    is( $response->feed->items, 25, "25 items per page default" );

}
