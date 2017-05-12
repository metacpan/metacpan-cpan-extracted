#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 14;
use JSON;
use Data::Dump qw( dump );
use Search::Tools::XML;

use Search::OpenSearch::Response::ExtJS;
use Search::OpenSearch::Response::XML;
use Search::OpenSearch::Response::JSON;
use Search::OpenSearch::Response::Tiny;

#######################################################################
## ExtJS

ok( my $extjs_response = Search::OpenSearch::Response::ExtJS->new(
        sort_info => 'score DESC',
    ),
    "new Response::ExtJS object"
);

ok( my $extjs = decode_json("$extjs_response"), "decode ExtJS" );

my $extjs_expected = {
    author     => "Search::OpenSearch::Response::ExtJS",
    build_time => undef,
    engine     => undef,
    facets     => undef,
    json_query => undef,
    link       => "",
    metaData   => {
        fields          => [ "uri", "title", "summary", "mtime", "score" ],
        idProperty      => "uri",
        limit           => 10,
        root            => "results",
        start           => 0,
        successProperty => "success",
        totalProperty   => "total",
        sortInfo => { field => 'score', direction => 'DESC' },
    },
    parsed_query => undef,
    query        => undef,
    results      => undef,
    search_time  => undef,
    success      => 1,
    suggestions  => undef,
    title        => "OpenSearch Results",
    total        => undef,
    updated      => 0,
    version      => $Search::OpenSearch::Response::ExtJS::VERSION,
};

is_deeply( $extjs, $extjs_expected, "extjs structure" );

#diag($extjs_response);
#diag( dump $extjs );

#####################################################################
## JSON

ok( my $json_response = Search::OpenSearch::Response::JSON->new(),
    "new Response::JSON object" );

ok( my $json = decode_json("$json_response"), "decode JSON" );

my $json_expected = {
    author       => "Search::OpenSearch::Response::JSON",
    build_time   => undef,
    engine       => undef,
    facets       => undef,
    json_query   => undef,
    link         => "",
    fields       => undef,
    parsed_query => undef,
    query        => undef,
    results      => undef,
    search_time  => undef,
    suggestions  => undef,
    title        => "OpenSearch Results",
    total        => undef,
    page_size    => 10,
    offset       => 0,
    sort_info    => undef,                                  #'score DESC',
    updated      => 0,
    version => $Search::OpenSearch::Response::JSON::VERSION,
};

is_deeply( $json, $json_expected, "json structure" );

#diag($json_response);
#diag( dump $json );

#####################################################################
## Tiny

ok( my $tiny_response = Search::OpenSearch::Response::Tiny->new(),
    "new Response::Tiny object" );

ok( my $tiny_json = decode_json("$tiny_response"), "decode Tiny JSON" );

my $tiny_expected = {
    facets      => undef,
    results     => undef,
    suggestions => undef,
    total       => undef,
    version     => $Search::OpenSearch::Response::Tiny::VERSION,
};

is_deeply( $tiny_json, $tiny_expected, "json structure" );

#diag($tiny_response);
#diag( dump $tiny_json );

#####################################################################
## XML

SKIP: {

    eval { require XML::Simple; };
    if ($@) {
        skip "XML::Simple required for XML Response tests", 5;
    }

    ok( my $xml_response
            = Search::OpenSearch::Response::XML->new( total => 10 ),
        "new Response::XML object"
    );

    ok( my $xml = XML::Simple::XMLin("$xml_response"), "decode XML" );
    ok( delete $xml->{updated}, "xml has updated field" );
    ok( delete $xml->{id},      "xml has id field" );

    my $xml_expected = {
        "author"   => "Search::OpenSearch::Response::XML",
        "category" => {
            term => "sos",
            sos  => {
                build_time  => {},
                engine      => {},
                facets      => {},
                search_time => {},
                suggestions => {},
                type        => "xml",
                xmlns       => "http://dezi.org/sos/schema",
            },
            scheme => 'http://dezi.org/sos/schema',
        },
        "link" => { href => "?t=XML&q=&p=10&o=0", rel => "self" },
        "opensearch:itemsPerPage" => 10,
        "opensearch:Query"        => {
            role         => "request",
            searchTerms  => "",
            startIndex   => 0,
            totalResults => 10
        },
        "opensearch:startIndex"   => 0,
        "opensearch:totalResults" => 10,
        "title"                   => "OpenSearch Results",
        "xmlns"                   => "http://www.w3.org/2005/Atom",
        "xmlns:opensearch"        => "http://a9.com/-/spec/opensearch/1.1/",
    };
    is_deeply( $xml, $xml_expected, "xml structure" );

    #dump($xml);

}
