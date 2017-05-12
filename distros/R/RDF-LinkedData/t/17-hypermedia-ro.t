#!/usr/bin/env perl

use FindBin qw($Bin);
use Plack::Request;

use strict;
use Test::More;# tests => 37;
use Test::RDF;
use RDF::Trine qw[iri literal blank variable statement];
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
my $rxparser   = RDF::Trine::Parser->new( 'rdfxml' );
my $model = RDF::Trine::Model->temporary_model;
my $base_uri = 'http://localhost';
$parser->parse_file_into_model( $base_uri, $file, $model );

ok($model, "We have a model");

{
	my $ec;
	if (can_load( modules => { 'RDF::Endpoint' => 0.03 })) {
		$ec = {endpoint_path => '/sparql'} ;
	}
	
	my $ld = RDF::LinkedData->new(model => $model, base_uri=>$base_uri, endpoint_config => $ec);
	
	isa_ok($ld, 'RDF::LinkedData');
	cmp_ok($ld->count, '>', 0, "There are triples in the model");
	
	
	{
		note "Get /foo, ensure nothing changed.";
		$ld->request(Plack::Request->new({}));
		my $response = $ld->response($base_uri . '/foo');
		isa_ok($response, 'Plack::Response');
		is($response->status, 303, "Returns 303");
		like($response->header('Location'), qr|/foo/data$|, "Location is OK");
	}
	
	{
		note "Get /foo/data";
		$ld->type('data');
		my $response = $ld->response($base_uri . '/foo');
		isa_ok($response, 'Plack::Response');
		is($response->status, 200, "Returns 200");
		my $retmodel = return_model($response->content, $rxparser);
		has_literal('This is a test', 'en', undef, $retmodel, "Test phrase in content");
	 SKIP: {
			skip "No endpoint configured", 2 unless ($ld->has_endpoint);
			has_uri($base_uri . '/sparql', $retmodel, 'SPARQL Endpoint URI is in model');
			pattern_target($retmodel);
		 SKIP: {
				skip "Redland behaves weirdly", 1 if ($RDF::Trine::Parser::Redland::HAVE_REDLAND_PARSER);
			pattern_ok(
						  statement(
										iri($base_uri . '/foo/data'),
										iri('http://rdfs.org/ns/void#inDataset'),
										variable('void')
									  ),
						  statement(
										variable('void'),
										iri('http://rdfs.org/ns/void#sparqlEndpoint'),
										iri($base_uri . '/sparql'),
									  ),
						  'SPARQL Endpoint is present'
						 )
		}
		}
	}
}

{
	my $ld = RDF::LinkedData->new(model => $model, base_uri=>$base_uri);
	
	isa_ok($ld, 'RDF::LinkedData');
	cmp_ok($ld->count, '>', 0, "There are triples in the model");
	
	
	{
		note "Get /foo, ensure nothing changed.";
		$ld->request(Plack::Request->new({}));
		my $response = $ld->response($base_uri . '/foo');
		isa_ok($response, 'Plack::Response');
		is($response->status, 303, "Returns 303");
		like($response->header('Location'), qr|/foo/data$|, "Location is OK");
	}
	
	{
		note "Get /foo/data, namespaces set";
		$ld->type('data');
		$ld->add_namespace_mapping(skos => 'http://www.w3.org/2004/02/skos/core#');
		$ld->add_namespace_mapping(dc => 'http://purl.org/dc/terms/' );
	   my $response = $ld->response($base_uri . '/foo');
		isa_ok($response, 'Plack::Response');
		is($response->status, 200, "Returns 200");
		unlike($response->content, qr/URI::Namespace=HASH/, 'We should have real URIs as vocabs');
		my $retmodel = return_model($response->content, $rxparser);
		has_literal('This is a test', 'en', undef, $retmodel, "Test phrase in content");
		has_object_uri('http://www.w3.org/2004/02/skos/core#', $retmodel, 'SKOS URI is present');
		pattern_target($retmodel);
		 SKIP: {
				skip "Redland behaves weirdly", 1 if ($RDF::Trine::Parser::Redland::HAVE_REDLAND_PARSER);
		pattern_ok(
						  statement(
										iri($base_uri . '/foo/data'),
										iri('http://rdfs.org/ns/void#inDataset'),
										variable('void')
									  ),
						  statement(
										variable('void'),
										iri('http://rdfs.org/ns/void#vocabulary'),
										iri('http://www.w3.org/2004/02/skos/core#'),
									  ),
						  statement(
										variable('void'),
										iri('http://rdfs.org/ns/void#vocabulary'),
										iri('http://purl.org/dc/terms/'),
									  ),
					    'Vocabularies are present'
						 )
		}
	}

}


{
	note "Now testing no endpoint";
	my $ld = RDF::LinkedData->new(model => $model, base_uri=>$base_uri);
	isa_ok($ld, 'RDF::LinkedData');
	cmp_ok($ld->count, '>', 0, "There are triples in the model");
	$ld->type('data');
	$ld->request(Plack::Request->new({}));
	my $response = $ld->response($base_uri . '/foo');
	isa_ok($response, 'Plack::Response');
	is($response->status, 200, "Returns 200");
	my $retmodel = return_model($response->content, $rxparser);
	has_literal('This is a test', 'en', undef, $retmodel, "Test phrase in content");
	hasnt_uri('http://rdfs.org/ns/void#sparqlEndpoint', $retmodel, 'No SPARQL endpoint entered');
}
{
	note "Now testing no endpoint";
	my $ld = RDF::LinkedData->new(model => $model, base_uri=>$base_uri, namespaces_as_vocabularies => 0);
	isa_ok($ld, 'RDF::LinkedData');
	cmp_ok($ld->count, '>', 0, "There are triples in the model");
	$ld->type('data');
	$ld->request(Plack::Request->new({}));
	my $response = $ld->response($base_uri . '/foo');
	isa_ok($response, 'Plack::Response');
	is($response->status, 200, "Returns 200");
	my $retmodel = return_model($response->content, $rxparser);
	has_literal('This is a test', 'en', undef, $retmodel, "Test phrase in content");
	hasnt_uri('http://rdfs.org/ns/void#vocabulary', $retmodel, 'No vocabs entered');
}



done_testing;


sub return_model {
	my ($content, $parser) = @_;
	my $retmodel = RDF::Trine::Model->temporary_model;
	$parser->parse_into_model( $base_uri, $content, $retmodel );
	return $retmodel;
}
