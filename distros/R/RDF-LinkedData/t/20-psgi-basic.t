#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 60 ;
use Test::RDF;
use Test::WWW::Mechanize::PSGI;
use Module::Load::Conditional qw[can_load];

my $tester = do "./script/linked_data.psgi" or BAIL_OUT("Can't do script: " . ($@ || $!));

BAIL_OUT("The application is not running") unless ($tester);

use Log::Any::Adapter;

Log::Any::Adapter->set($ENV{LOG_ADAPTER} || 'Stderr') if $ENV{TEST_VERBOSE};

{
    note "Get /foo, no redirects";
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester, requests_redirectable => []);
    my $res = $mech->get("/foo");
    is($mech->status, 303, "Returns 303");
    like($res->header('Location'), qr|/foo/data$|, "Location is OK");
	 like($res->header('Server'), qr|RDF::LinkedData/$RDF::LinkedData::VERSION|, 'Server header is there' );
}


foreach my $accept_header (('text/html',
			    'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
			    'text/html, application/xml;q=0.9, application/xhtml+xml, image/png, image/jpeg, image/gif, image/x-xbitmap, */*;q=0.1',
			    'application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5')) {
    note "Get /foo, no redirects, ask for $accept_header";
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester, requests_redirectable => []);
    $mech->default_header('Accept' => $accept_header);
    my $res = $mech->get("/foo");
    is($mech->status, 303, "Returns 303");
    is($res->header('Location'), 'http://en.wikipedia.org/wiki/Foo', "Location is Wikipedia page");
}


{
    note "Get /foo/page, no redirects";
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester, requests_redirectable => []);
    my $res = $mech->get("/foo/page");
    is($mech->status, 301, "Returns 301");
    is($res->header('Location'), 'http://en.wikipedia.org/wiki/Foo', "Location is Wikipedia page");
}

{
    note "Get /foo, no redirects, ask for RDF/XML";
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester, requests_redirectable => []);
    $mech->default_header('Accept' => 'application/rdf+xml');
    my $res = $mech->get("/foo");
    is($mech->status, 303, "Returns 303");
    like($res->header('Location'), qr|/foo/data$|, "Location is OK");
}

{
    note "Get /foo, no redirects, use Tabulators Accept header";
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester, requests_redirectable => []);
    $mech->default_header('Accept' => 'application/rdf+xml, application/xhtml+xml;q=0.3, text/xml;q=0.2, application/xml;q=0.2, text/html;q=0.3, text/plain;q=0.1, text/n3, text/rdf+n3;q=0.5, application/x-turtle;q=0.2, text/turtle;q=1');
    my $res = $mech->get("/foo");
    is($mech->status, 303, "Returns 303");
    like($res->header('Location'), qr|/foo/data$|, "Location is OK");
}

{
    note "Get /dahut, no redirects, ask for RDF/XML";
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester, requests_redirectable => []);
    $mech->default_header('Accept' => 'application/rdf+xml');
    my $res = $mech->get("/dahut");
    is($mech->status, 404, "Returns 404");
}


my $rxparser = RDF::Trine::Parser->new( 'rdfxml' );
my $base_uri = 'http://localhost/';

{
    note "Get /foo, ask for RDF/XML";
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
    $mech->default_header('Accept' => 'application/rdf+xml');
    $mech->get_ok("/foo");
    is($mech->ct, 'application/rdf+xml', "Correct content-type");
    like($mech->uri, qr|/foo/data$|, "Location is OK");
    my $model = RDF::Trine::Model->temporary_model;
    is_valid_rdf($mech->content, 'rdfxml', 'Returns valid RDF/XML');
    $rxparser->parse_into_model( $base_uri, $mech->content, $model );
    has_subject($base_uri . 'foo', $model, "Subject URI in content");
    has_literal('This is a test', 'en', undef, $model, "Test phrase in content");
}

{
    note "Get /foo, ask for Turtle";
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
    $mech->default_header('Accept' => 'application/turtle');
    $mech->get_ok("/foo");
    is($mech->ct, 'application/turtle', "Correct content-type");
    like($mech->uri, qr|/foo/data$|, "Location is OK");
    my $model = RDF::Trine::Model->temporary_model;
    is_valid_rdf($mech->content, 'turtle', 'Returns valid Turtle');
    my $parser = RDF::Trine::Parser->new( 'turtle' );
    $parser->parse_into_model( $base_uri, $mech->content, $model );
    has_subject($base_uri . 'foo', $model, "Subject URI in content");
    has_literal('This is a test', 'en', undef, $model, "Test phrase in content");
}

{
    note "Get /foo/data, ask for XHTML";
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
    $mech->default_header('Accept' => 'application/xhtml+xml');
    $mech->get_ok("/foo/data");
    TODO: {
	local $TODO = "Seems like something after Plack modifies the content type";
	is($mech->ct, 'application/xhtml+xml', "Correct content-type");
    }
    like($mech->uri, qr|/foo/data$|, "Location is OK");
	 $mech->content_like(qr|about=\"http://\S+?/foo\"|, 'Subject URI is OK in RDFa' );
	 $mech->content_contains('rel="foaf:page"', 'foaf:page is in RDFa' );
}

{
    note "Get /bar/baz/bing, no redirects, ask for RDF/XML";
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester, requests_redirectable => []);
    $mech->default_header('Accept' => 'application/rdf+xml'); 
	 $mech->add_header('Origin' => 'http://example.org');
    my $res = $mech->get("/bar/baz/bing");
    is($mech->status, 303, "Returns 303");
    like($res->header('Location'), qr|/bar/baz/bing/data$|, "Location is OK");
	 SKIP: {
			skip 'CrossOrigin not installed', 1 unless can_load( modules => { 'Plack::Middleware::CrossOrigin' => 0 });
			is($res->header('Access-Control-Allow-Origin'), '*', 'CORS header OK');
		}
	 like($mech->response->header('Server'), qr|RDF::LinkedData/$RDF::LinkedData::VERSION|, 'Server header is there' );
}


{
    note "Get /bar/baz/bing";
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
    $mech->default_header('Accept' => 'text/html');
    $mech->get_ok("/bar/baz/bing");
    is($mech->ct, 'text/html', "Correct content-type");
    like($mech->uri, qr|/bar/baz/bing/page$|, "Location is OK");
    $mech->title_is('Testing with longer URI.', "Title is correct");
    $mech->has_tag('h1', 'Testing with longer URI.', "Title in body is correct");
	 $mech->content_like(qr|about=\"http://\S+?/bar/baz/bing\"|, 'Subject URI is OK in RDFa' );
}

{
    note "Post /bar/baz/bing";
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);

    $mech->post("/bar/baz/bing", { 'Content-Type' => 'text/turtle', 
														 Content => "<$base_uri/foo> <http://example.org/new2> \"Merged triple\"\@en" });
    is($mech->status, '405', "Method is not allowed");
}

{
    note "Post /bar/baz/bing/data";
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);

    $mech->post("/bar/baz/bing/data", { 'Content-Type' => 'text/turtle', 
														 Content => "<$base_uri/foo> <http://example.org/new2> \"Merged triple\"\@en" });
    is($mech->status, '405', "Method is not allowed");
}




{
    note "Get /bar/baz/bing, ask for RDF/XML";
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
    $mech->default_header('Accept' => 'application/rdf+xml');
    $mech->get_ok("/bar/baz/bing");
    is($mech->ct, 'application/rdf+xml', "Correct content-type");
    like($mech->uri, qr|/bar/baz/bing/data$|, "Location is OK");
	 unlike($mech->response->header("ETag"), qr/^\"?http/, 'Etag should not start with http');
	 like($mech->response->header("ETag"), qr/^\"\w+\"$/, 'Returns a suitable, quoted ETag');
    my $model = RDF::Trine::Model->temporary_model;
    is_valid_rdf($mech->content, 'rdfxml', 'Returns valid RDF/XML');
    $rxparser->parse_into_model( $base_uri, $mech->content, $model );
    has_subject($base_uri . 'bar/baz/bing', $model, "Subject URI in content");
    has_literal('Testing with longer URI.', 'en', undef, $model, "Test phrase in content");
}



TODO: {
    local $TODO = "We really should return 406 if no acceptable version is there, shouldn't we?";
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
    $mech->default_header('Accept' => 'application/foobar');
    my $res = $mech->get("/foo/data");
    is($mech->status, 406, "Returns 406");
}


{
    note "Check for SPARQL endpoint";
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
    $mech->get("/sparql");
    isnt($mech->status, 200, "/sparql doesn't return 200 for a get");
    $mech->post("/sparql");
    isnt($mech->status, 200, "/sparql doesn't return 200 for a post");
    is($mech->status, 405, "/sparql returns 405 for a post");
    $mech->get("/");
    isnt($mech->status, 200, "root doesn't return 200");

}

done_testing();
