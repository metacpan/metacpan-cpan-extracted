#!/usr/bin/env perl

use FindBin qw($Bin);
use Plack::Request;

use strict;
use Test::More;
use Test::RDF;
use Log::Any::Adapter;
use Module::Load::Conditional qw[check_install];
use Test::RDF;
use RDF::Trine qw[iri literal blank variable statement];
use RDF::Trine::Store::Hexastore;

unless (defined(check_install( module => 'RDF::Generator::Void', version => 0.02))) {
  plan skip_all => 'You need RDF::Generator::Void for this test'
}

Log::Any::Adapter->set($ENV{LOG_ADAPTER} || 'Stderr') if $ENV{TEST_VERBOSE};

my $file = $Bin . '/data/basic.ttl';

use_ok('RDF::LinkedData');
use_ok('RDF::Generator::Void');

my $parser     = RDF::Trine::Parser->new( 'turtle' );
my $store = RDF::Trine::Store::Hexastore->temporary_store;
my $model = RDF::Trine::Model->new($store);
my $base_uri = 'http://localhost';
my $ns = URI::NamespaceMap->new(['rdf', 'rdfs', 'void', 'xsd']);

$parser->parse_file_into_model( $base_uri, $file, $model );

ok($model, "We have a model");
is($model->size, 3, "We have a model with 3 statements");


my $ld = RDF::LinkedData->new(model => $model, base_uri => $base_uri, namespaces_as_vocabularies => 1, void_config => { urispace => 'http://localhost' });

isa_ok($ld, 'RDF::LinkedData');
is($ld->count, 3, "There are 3 triples in the model");

{
	note "Basic VoID test";
	$ld->request(Plack::Request->new({}));
	$ld->void->add_licenses('http://example.org/open-data-license');
	my $response = $ld->response($base_uri);
	isa_ok($response, 'Plack::Response');
	my $content = $response->content;
	is_valid_rdf($content, 'turtle', 'Returns valid Turtle');
	my $retmodel = RDF::Trine::Model->temporary_model;
	$parser->parse_into_model( $base_uri, $content, $retmodel );
	has_subject($base_uri . '/#dataset-0', $retmodel, "Subject URI in content");
	has_predicate('http://purl.org/dc/terms/license', $retmodel, "Has license predicate");
	has_object_uri('http://example.org/open-data-license', $retmodel, "Has license object");
	pattern_target($retmodel);
	pattern_ok(
				  statement(
								iri($base_uri . '/#dataset-0'),
								iri($ns->void->triples),
								literal(3, undef, iri($ns->xsd->integer))
							  ),
				  statement(
								iri($base_uri . '/#dataset-0'),
								iri($ns->rdf->type),
								iri($ns->void->Dataset)
							  ),
				  'Common statements are there');
}

{
	note "Add a statement";

	is($ld->count, 3, "There are 3 triples in the model");
	is($ld->last_etag, $ld->current_etag, 'Etags have not changed');
	$ld->model->add_statement(statement(iri($base_uri . '/foo'), iri($ns->rdfs->label), literal('DAHUT')));
	is($ld->count, 4, "There are 4 triples in the model");
	isnt($ld->last_etag, $ld->current_etag, 'Etags have changed');
	$ld->type('data');
	$ld->request(Plack::Request->new({}));
	my $fresponse = $ld->response($base_uri .'/foo');
	isa_ok($fresponse, 'Plack::Response');
	like($fresponse->content, qr/DAHUT/, 'Test string in content');

	$ld->request(Plack::Request->new({}));
	my $response = $ld->response($base_uri);
	isa_ok($response, 'Plack::Response');
	my $content = $response->content;
	is_valid_rdf($content, 'turtle', 'Returns valid Turtle');
	my $retmodel = RDF::Trine::Model->temporary_model;
	$parser->parse_into_model( $base_uri, $content, $retmodel );
	has_subject($base_uri . '/#dataset-0', $retmodel, "Subject URI in content");
	pattern_target($retmodel);
	pattern_ok(
				  statement(
								iri($base_uri . '/#dataset-0'),
								iri($ns->void->triples),
								literal(4, undef, iri($ns->xsd->integer))
							  ),
				  statement(
								iri($base_uri . '/#dataset-0'),
								iri($ns->rdf->type),
								iri($ns->void->Dataset)
							  ),
				  'Common statements are there');
}


{
	note 'Test with DBI temp store';
	my $dstore = RDF::Trine::Store::DBI->temporary_store;
	my $dmodel = RDF::Trine::Model->new($dstore);
	$parser->parse_file_into_model( $base_uri, $file, $dmodel );

	ok($dmodel, "We have a model");
	is($dmodel->size, 3, "We have a model with 3 statements");

	my $dld = RDF::LinkedData->new(model => $dmodel, base_uri => $base_uri, namespaces_as_vocabularies => 1, void_config => { urispace => 'http://localhost' });

	isa_ok($dld, 'RDF::LinkedData');
	is($dld->count, 3, "There are 3 triples in the model");
	is($dld->last_etag, $dld->current_etag, 'Etags are the same');
	is($dld->current_etag, undef, 'Current Etag is undefined');
	$dld->request(Plack::Request->new({}));
	my $response3 = $dld->response($base_uri);
	isa_ok($response3, 'Plack::Response');
	my $content3 = $response3->content;
	is_valid_rdf($content3, 'turtle', 'Returns valid Turtle');
	my $retmodel3 = RDF::Trine::Model->temporary_model;
	$parser->parse_into_model( $base_uri, $content3, $retmodel3 );
	has_subject($base_uri . '/#dataset-0', $retmodel3, "Subject URI in content");
	pattern_target($retmodel3);
	pattern_ok(
				  statement(
								iri($base_uri . '/#dataset-0'),
								iri($ns->void->triples),
								literal(3, undef, iri($ns->xsd->integer))
							  ),
				  statement(
								iri($base_uri . '/#dataset-0'),
								iri($ns->rdf->type),
								iri($ns->void->Dataset)
							  ),
				  'Three triples should be counted');

	$dld->model->add_statement(statement(iri($base_uri . '/foo'), iri($ns->rdfs->label), literal('DAHUT')));
	is($dld->count, 4, "There are 4 triples in the model");
	is($dld->last_etag, $dld->current_etag, 'Etags are still the same');
	is($dld->current_etag, undef, 'Current Etag is still undefined');
	$dld->type('data');
	$dld->request(Plack::Request->new({}));
	my $fresponse = $dld->response($base_uri .'/foo');
	isa_ok($fresponse, 'Plack::Response');
	like($fresponse->content, qr/DAHUT/, 'Test string in content');

	$dld->request(Plack::Request->new({}));
	my $response = $dld->response($base_uri);
	isa_ok($response, 'Plack::Response');
	my $content = $response->content;
	is_valid_rdf($content, 'turtle', 'Returns valid Turtle');
	my $retmodel = RDF::Trine::Model->temporary_model;
	$parser->parse_into_model( $base_uri, $content, $retmodel );
	has_subject($base_uri . '/#dataset-0', $retmodel, "Subject URI in content");
	pattern_target($retmodel);
	pattern_ok(
				  statement(
								iri($base_uri . '/#dataset-0'),
								iri($ns->void->triples),
								literal(4, undef, iri($ns->xsd->integer))
							  ),
				  statement(
								iri($base_uri . '/#dataset-0'),
								iri($ns->rdf->type),
								iri($ns->void->Dataset)
							  ),
				  '4 statements should be counted');
}

done_testing;
