#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 22;
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

{

    package MyServer;
    @MyServer::ISA = ('Search::OpenSearch::Server::Plack');

    sub log {
        my ( $self, $msg ) = @_;
        Test::More::diag("$self: $msg");
    }

}

SKIP: {

    my $index_path = $ENV{OPENSEARCH_INDEX};
    if ( !defined $index_path or !-d $index_path ) {
        diag("set OPENSEARCH_INDEX to valid path to test Plack with Lucy");
        skip "set OPENSEARCH_INDEX to valid path to test Plack with Lucy", 22;
    }
    eval "use Plack::Test";
    if ($@) {
        skip "Plack::Test not available", 22;
    }
    eval "use Search::OpenSearch::Engine::Lucy";
    if ($@) {
        skip "Search::OpenSearch::Engine::Lucy not available", 22;
    }

    require Search::OpenSearch::Server::Plack;
    require HTTP::Request;

    my $app = MyServer->new(
        engine_config => {
            type  => 'Lucy',
            index => [$index_path],
        },
        stats_logger => MyStats->new(),
        http_allow   => [qw( GET PUT DELETE )],    # no POST
    );

    test_psgi(
        app    => $app,
        client => sub {
            my $cb  = shift;
            my $req = HTTP::Request->new( GET => 'http://localhost/?q=test' );
            my $res = $cb->($req);

            #diag( $res->content );
            ok( my $results = decode_json( $res->content ),
                "decode_json response" );
            is( $results->{query}, "test", "query param returned" );
            cmp_ok( $results->{total}, '>=', 1, ">= one hit" );
            ok( exists $results->{search_time}, "search_time key exists" );
            is( $results->{title}, qq/OpenSearch Results/, "got title" );
        }
    );

    test_psgi(
        app    => $app,
        client => sub {
            my $cb  = shift;
            my $req = HTTP::Request->new(
                GET => 'http://localhost/?q=test&x=foo&x=bar' );
            my $res = $cb->($req);

            #diag( $res->content );
            is( $res->code, 500, "unknown fields in 'x' param" );
            ok( my $results = decode_json( $res->content ),
                "decode_json response" );
            is( $results->{success}, 0,
                "json response on error shows success==0" );
        }
    );

    test_psgi(
        app    => $app,
        client => sub {
            my $cb  = shift;
            my $req = HTTP::Request->new( GET => 'http://localhost/' );
            my $res = $cb->($req);
            is( $res->content, qq/'q' required/, "missing 'q' param" );
            is( $res->code, 400, "bad request status" );
        }
    );

    # REST

    test_psgi(
        app    => $app,
        client => sub {
            my $cb  = shift;
            my $req = HTTP::Request->new( GET => 'http://localhost/foo/bar' );
            my $res = $cb->($req);

            #dump $res;
            is( $res->code, 404, "foo/bar does not exist" );
        }
    );

    test_psgi(
        app    => $app,
        client => sub {
            my $cb = shift;
            my $req = HTTP::Request->new( PUT => 'http://localhost/foo/bar' );
            $req->content_type('application/xml');
            $req->content('<doc><title>i am a test</title></doc>');
            $req->content_length( length( $req->content ) );
            my $res = $cb->($req);

            #dump $res;
            ok( my $json = decode_json( $res->content ),
                "decode content as JSON" );

            #dump $json;
            is( $json->{doc}->{title}, 'i am a test', "test title" );
            is( $res->code,            201,           "PUT ok" );
        }
    );

    test_psgi(
        app    => $app,
        client => sub {
            my $cb = shift;
            my $req
                = HTTP::Request->new( DELETE => 'http://localhost/foo/bar' );
            my $res = $cb->($req);

            #dump $res;
            ok( my $json = decode_json( $res->content ),
                "decode content as JSON" );

            #dump $json;
            is( $res->code, 200, "DELETE ok" );
        }
    );

    test_psgi(
        app    => $app,
        client => sub {
            my $cb = shift;
            my $req
                = HTTP::Request->new( POST => 'http://localhost/foo/bar' );
            $req->content_type('application/xml');
            $req->content('<doc><title>i am a test</title></doc>');
            $req->content_length( length( $req->content ) );
            my $res = $cb->($req);

            #dump $res;
            ok( my $json = decode_json( $res->content ),
                "decode content as JSON" );

            #dump $json;
            is( $res->code, 405, "POST not allowed" );
        }
    );

}
