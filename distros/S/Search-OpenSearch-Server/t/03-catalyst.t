#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib/MyApp/lib';
use Test::More tests => 20;
use Data::Dump qw( dump );
use JSON;

{

    package MyStats;

    sub new {
        return bless {}, shift;
    }

    sub log {
        my ( $self, $req, $resp ) = @_;
        Test::More::ok( ref $resp, "response is a ref" );

        #Test::More::diag( Data::Dump::dump $resp );

    }

}

SKIP: {

    my $index_path = $ENV{OPENSEARCH_INDEX};
    if ( !defined $index_path or !-d $index_path ) {
        diag("set OPENSEARCH_INDEX to valid path to test Plack with Lucy");
        skip "set OPENSEARCH_INDEX to valid path to test Plack with Lucy", 20;
    }
    eval "use Catalyst::Test qw(MyApp)";
    if ($@) {
        warn $@;
        skip "Catalyst::Test not available", 20;
    }
    eval "use HTTP::Request::Common";
    if ($@) {
        warn $@;
        skip "HTTP::Request::Common not available", 20;
    }
    eval "use Search::OpenSearch::Engine::Lucy";
    if ($@) {
        skip "Search::OpenSearch::Engine::Lucy not available", 20;
    }

    my $res;
    my $sos_resp;

    # basic search
    ok( $res = request( GET('/sos/search?q=test') ),
        "GET /sos/search?q=test" );

    #dump $res;
    ok( $sos_resp = decode_json( $res->content ), "decode JSON content" );
    like( $sos_resp->{total}, qr/^\d+$/, "total is numeric" );
    my $orig_total = $sos_resp->{total};

    # alter index
    my $req = HTTP::Request->new(
        PUT => 'http://localhost/sos/',
        [ 'X-SOS-Content-Location' => 'foo/bar' ],    # explicit path
    );
    $req->content_type('application/xml');
    $req->content('<doc><title>i am a test</title></doc>');
    $req->content_length( length( $req->content ) );
    ok( $res = request($req), "PUT request" );

    #dump $res;
    ok( $sos_resp = decode_json( $res->content ),
        "decode JSON response to PUT" );

    #dump $sos_resp;
    is( $sos_resp->{success}, 1, "successful PUT" );

    # search again
    ok( $res = request( GET('/sos/search?q=test') ),
        "GET /sos/search?q=test" );

    #dump $res;
    ok( $sos_resp = decode_json( $res->content ), "decode JSON content" );
    is( $sos_resp->{total}, ( $orig_total + 1 ), "total is +1" );

    # clean up
    $req = HTTP::Request->new(
        DELETE => 'http://localhost/sos/',
        [ 'X-SOS-Content-Location' => 'foo/bar' ],    # explicit path
    );
    ok( $res = request($req), "PUT request" );

    #dump $res;
    ok( $sos_resp = decode_json( $res->content ),
        "decode JSON response to PUT" );

    #dump $sos_resp;
    is( $sos_resp->{success}, 1, "successful DELETE" );

    # search again
    ok( $res = request( GET('/sos/search?q=test') ),
        "GET /sos/search?q=test" );

    #dump $res;
    ok( $sos_resp = decode_json( $res->content ), "decode JSON content" );
    is( $sos_resp->{total}, $orig_total, "total is $orig_total" );

}
