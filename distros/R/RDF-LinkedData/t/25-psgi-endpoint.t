#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::RDF;
use Test::WWW::Mechanize::PSGI;
use Module::Load::Conditional qw[can_load];


unless (can_load( modules => { 'RDF::Endpoint' => 0.03 })) {
  plan skip_all => 'You need RDF::Endpoint for this test'
}




$ENV{'RDF_LINKEDDATA_CONFIG_LOCAL_SUFFIX'} = 'end';

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
}

{
    note "Post /foo, no redirects";
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester, requests_redirectable => []);
    my $res = $mech->post("/foo");
    is($mech->status, 405, "Returns 405");
}

{
    note "Post /foo/data, no redirects";
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester, requests_redirectable => []);
    my $res = $mech->post("/foo/data");
    is($mech->status, 405, "Returns 405");
}


{
    note "Get /foo, no redirects, ask for RDF/XML";
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester, requests_redirectable => []);
    $mech->default_header('Accept' => 'application/rdf+xml');
    my $res = $mech->get("/foo");
    is($mech->status, 303, "Returns 303");
    like($res->header('Location'), qr|/foo/data$|, "Location is OK");
}



my $rxparser = RDF::Trine::Parser->new( 'rdfxml' );
my $base_uri = 'http://localhost/';



{
    note "Get /bar/baz/bing, ask for RDF/XML";
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
    $mech->default_header('Accept' => 'application/rdf+xml');
    $mech->get_ok("/bar/baz/bing");
    is($mech->ct, 'application/rdf+xml', "Correct content-type");
    like($mech->uri, qr|/bar/baz/bing/data$|, "Location is OK");
    my $model = RDF::Trine::Model->temporary_model;
    is_valid_rdf($mech->content, 'rdfxml', 'Returns valid RDF/XML');
    $rxparser->parse_into_model( $base_uri, $mech->content, $model );
    has_subject($base_uri . 'bar/baz/bing', $model, "Subject URI in content");
    has_literal('Testing with longer URI.', 'en', undef, $model, "Test phrase in content");
	 has_uri('http://rdfs.org/ns/void#sparqlEndpoint', $model, 'SPARQL endpoint link in data');
	 has_uri($base_uri . '/sparql', $model, 'SPARQL endpoint in data');
}




{
    note "Check for SPARQL endpoint using get";
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
    $mech->get_ok("/sparql", "Returns 200");
    $mech->title_like(qr/SPARQL/, "Title contains the word SPARQL");
    $mech->submit_form_ok( {
            form_id => 'queryform',
            fields      => {
            query => 'DESCRIBE <http://localhost/bar/baz/bing> WHERE {}',
				'media-type' => 'text/turtle'
          },
        }, 'Submitting DESCRIBE query.'
    );
    is_rdf($mech->content, 'turtle', 
	   '<http://localhost/bar/baz/bing> <http://www.w3.org/2000/01/rdf-schema#label> "Testing with longer URI."@en .',
	   'turtle',  'SPARQL Query returns correct triple');
}

{
    note "Check for SPARQL endpoint using post";
    my $mech = Test::WWW::Mechanize::PSGI->new(app => $tester);
    $mech->post_ok('/sparql', {
							query => 'DESCRIBE <http://localhost/bar/baz/bing> WHERE {}',
							'Accept' => 'application/rdf+xml'
						  },
						  'Submitting DESCRIBE query.');
    is_rdf($mech->content, 'rdfxml', 
	   '<http://localhost/bar/baz/bing> <http://www.w3.org/2000/01/rdf-schema#label> "Testing with longer URI."@en .',
	   'turtle',  'SPARQL Query returns correct triple');
}



done_testing();
