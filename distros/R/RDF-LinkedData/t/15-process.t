#!/usr/bin/env perl

use FindBin qw($Bin);
use Plack::Request;

use strict;
use Test::More tests => 39;
use Test::RDF;
use Log::Any::Adapter;
use Module::Load::Conditional qw[can_load];

Log::Any::Adapter->set($ENV{LOG_ADAPTER} || 'Stderr') if $ENV{TEST_VERBOSE};

my $file = $Bin . '/data/basic.ttl';

BEGIN {
    use_ok('RDF::LinkedData');
    use_ok('RDF::Helper::Properties');
    use_ok('RDF::Trine::Parser');
    use_ok('RDF::Trine::Model');
}



my $parser     = RDF::Trine::Parser->new( 'turtle' );
my $model = RDF::Trine::Model->temporary_model;
my $base_uri = 'http://localhost';
$parser->parse_file_into_model( $base_uri, $file, $model );

ok($model, "We have a model");

my $ld = can_load( modules => { 'RDF::Endpoint' => 0.03 })
  ? RDF::LinkedData->new(model => $model, base_uri=>$base_uri,
			 endpoint_config => {endpoint_path => '/sparql'})
  : RDF::LinkedData->new(model => $model, base_uri=>$base_uri);

isa_ok($ld, 'RDF::LinkedData');
cmp_ok($ld->count, '>', 0, "There are triples in the model");


{
    note "Get /foo";
    $ld->request(Plack::Request->new({}));
    my $response = $ld->response($base_uri . '/foo');
    isa_ok($response, 'Plack::Response');
    is($response->status, 303, "Returns 303");
    like($response->header('Location'), qr|/foo/data$|, "Location is OK");
}

{
    note "Get /foo, ask for text/html";
    $ld->request(Plack::Request->new({ HTTP_ACCEPT => 'text/html' }));
    my $response = $ld->response($base_uri . '/foo');
    isa_ok($response, 'Plack::Response');
    is($response->status, 303, "Returns 303");
    is($response->header('Location'), 'http://en.wikipedia.org/wiki/Foo', "Location is Wikipedia page");
}

{
    note "Get /foo, use Firefox' default Accept header";
    $ld->request(Plack::Request->new({ HTTP_ACCEPT => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'}));
    my $response = $ld->response($base_uri . '/foo');
    isa_ok($response, 'Plack::Response');
    is($response->status, 303, "Returns 303");
    is($response->header('Location'), 'http://en.wikipedia.org/wiki/Foo', "Location is Wikipedia page");
}

{
    note "Get /foo, ask for RDF/XML";
    $ld->request(Plack::Request->new({ HTTP_ACCEPT => 'application/rdf+xml'}));
    my $response = $ld->response($base_uri . '/foo');
    isa_ok($response, 'Plack::Response');
    is($response->status, 303, "Returns 303");
    like($response->header('Location'), qr|/foo/data$|, "Location is OK");
}


{
    note "Get /foo, ask for Turtle";
    $ld->request(Plack::Request->new({ HTTP_ACCEPT => 'application/turtle'}));
    my $response = $ld->response($base_uri . "/foo");
    like($response->header('Location'), qr|/foo/data$|, "Location is OK");
}


{
    note "Get /dahut, ask for RDF/XML";
    $ld->request(Plack::Request->new({ HTTP_ACCEPT => 'application/rdf+xml'}));
    my $response = $ld->response($base_uri . '/dahut');
    isa_ok($response, 'Plack::Response');
    is($response->status, 404, "Returns 404");
}


{
    note "Get /foo/page";
    $ld->type('page');
    my $response = $ld->response($base_uri . '/foo');
    isa_ok($response, 'Plack::Response');
    is($response->status, 301, "Returns 301");
    is($response->header('Location'), 'http://en.wikipedia.org/wiki/Foo', "Location is Wikipedia page");
}

{
    note "Get /bar/baz/bing";
    $ld->request(Plack::Request->new({ HTTP_ACCEPT => 'text/html'}));
    my $response = $ld->response($base_uri . "/bar/baz/bing");
    isa_ok($response, 'Plack::Response');
    is($response->status, 303, "Returns 303");
    like($response->header('Location'), qr|/bar/baz/bing/page$|, "Location is OK");
}

{
    note "Get /bar/baz/bing/page";
    $ld->type('page');
    my $response = $ld->response($base_uri . "/bar/baz/bing");
    isa_ok($response, 'Plack::Response');
    is($response->status, 200, "Returns 200");
    is($response->content_type, 'text/html', 'Returns HTML');
    like($response->body, qr|Testing with longer URI\.|, "Test phrase in content");
    my $test = 'about="' . $base_uri . '/bar/baz/bing"';
    like($response->body, qr|$test|, "Subject URI OK");
}


{
    note "Get /bar/baz/bing, ask for RDF/XML";
    $ld->request(Plack::Request->new({ HTTP_ACCEPT => 'application/rdf+xml'}));
    my $response = $ld->response($base_uri . "/bar/baz/bing");
    is($response->status, 303, "Returns 303");
    like($response->header('Location'), qr|/bar/baz/bing/data$|, "Location is OK");
}




{
    note "Get /foo/data";
    $ld->type('data');
    my $response = $ld->response($base_uri . '/foo');
    isa_ok($response, 'Plack::Response');
    is($response->status, 200, "Returns 200");
	 like($response->header("ETag"), qr/^\"\w+\"$/, 'Returns a suitable, quoted ETag');
    my $model = RDF::Trine::Model->temporary_model;
    my $parser = RDF::Trine::Parser->new( 'rdfxml' );
    $parser->parse_into_model( $base_uri, $response->body, $model );
    has_literal('This is a test', 'en', undef, $model, "Test phrase in content");
}

