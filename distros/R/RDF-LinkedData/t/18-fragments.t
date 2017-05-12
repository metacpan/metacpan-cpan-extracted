#!/usr/bin/env perl

use FindBin qw($Bin);
use Plack::Request;

use strict;
use Test::More;# tests => 37;
use Test::RDF;
use RDF::Trine qw[iri literal blank variable statement];
use Log::Any::Adapter;
use URI::NamespaceMap;
use Module::Load::Conditional qw[check_install];
use URI::Escape;

unless (defined(check_install( module => 'RDF::Generator::Void', version => 0.02))) {
  plan skip_all => 'You need RDF::Generator::Void for this test'
}

Log::Any::Adapter->set($ENV{LOG_ADAPTER} || 'Stderr') if $ENV{TEST_VERBOSE};

my $file = $Bin . '/data/fragments.ttl';

use_ok('RDF::LinkedData');
use_ok('RDF::Generator::Void');

my $ns = URI::NamespaceMap->new(['rdf', 'rdfs', 'foaf', 'void', 'dc', 'xsd']);
$ns->add_mapping('hydra' => 'http://www.w3.org/ns/hydra/core#');

my $parser     = RDF::Trine::Parser->new( 'turtle' );
my $rxparser   = RDF::Trine::Parser->new( 'rdfxml' );
my $model = RDF::Trine::Model->temporary_model;
my $base_uri = 'http://localhost';
$parser->parse_file_into_model( $base_uri, $file, $model );

ok($model, "We have a model");

my $ec = {fragments_path => '/fragments'} ;

my $void_subject = iri($base_uri . '/#dataset-0');


{
	note 'Testing the query interface itself';

	my $ld = RDF::LinkedData->new(model => $model,
											base_uri => $base_uri, 
											namespaces_as_vocabularies => 1, 
											void_config => { urispace => 'http://localhost' }, 
											fragments_config => $ec
										  );

	isa_ok($ld, 'RDF::LinkedData');

	$ld->request(Plack::Request->new({}));

	{
		my $response = $ld->response($base_uri . '/fragments?subject=' . uri_escape_utf8('http://localhost/foo'));
		isa_ok($response, 'Plack::Response');
		is($response->status, 200, "Returns 200");
		my $retmodel = return_model($response->content, $parser);
		has_literal('This is a test', 'en', undef, $retmodel, "Test phrase in content");
		pattern_target($retmodel);
		pattern_ok(
					  statement(iri($base_uri . '/foo'),
									iri($ns->rdfs->label),
									literal("This is a test", 'en')),
					  statement(iri($base_uri . '/foo'),
									iri($ns->foaf->page),
									iri('http://en.wikipedia.org/wiki/Foo'))
					  , 'Both triples present',
					 );
		
		pattern_ok(
					  statement(iri($base_uri . '/fragments?subject=' . uri_escape_utf8('http://localhost/foo')),
									iri($ns->void->triples),
									literal("2", undef, iri($ns->xsd->integer))),
					  statement(iri($base_uri . '/fragments?subject=' . uri_escape_utf8('http://localhost/foo')),
									iri($ns->hydra->totalItems),
									literal("2", undef, iri($ns->xsd->integer))),
					  , 'Triple count is correct',
					 );
		
		pattern_ok(	 statement(iri($base_uri . '/fragments?subject=' . uri_escape_utf8('http://localhost/foo')),
									iri($ns->dc->source),
									$void_subject),
					  , 'Void Subject in dc:source'
					 );

		has_subject($void_subject->uri_value, $retmodel, "Void Subject URI in content");

		pattern_ok(
					  statement($void_subject,
									iri($ns->rdf->type),
									iri($ns->hydra->Collection)),
					  statement($void_subject,
									iri($ns->hydra->search),
									blank('template')),
					  statement(blank('template'),
									iri($ns->hydra->template),
									literal($base_uri . '/fragments{?subject,predicate,object}')),
					  statement(blank('template'),
					  				iri($ns->hydra->mapping),
					  				blank('subject')),
					  statement(blank('template'),
					  				iri($ns->hydra->mapping),
					  				blank('predicate')),
					  statement(blank('template'),
					  				iri($ns->hydra->mapping),
					  				blank('predicate')),
					  statement(blank('template'),
					  				iri($ns->hydra->mapping),
					  				blank('object')),
					  statement(blank('subject'),
									iri($ns->hydra->property),
									iri($ns->rdf->subject)),
					  statement(blank('subject'),
									iri($ns->hydra->variable),
									literal('subject')),
					  statement(blank('predicate'),
									iri($ns->hydra->property),
									iri($ns->rdf->predicate)),
					  statement(blank('predicate'),
									iri($ns->hydra->variable),
									literal('predicate')),
					  statement(blank('object'),
									iri($ns->hydra->property),
									iri($ns->rdf->object)),
					  statement(blank('object'),
									iri($ns->hydra->variable),
									literal('object')),
					  "Control statements OK");
   }
	
	{
		my $response = $ld->response($base_uri . '/fragments?predicate=' . uri_escape_utf8('http://www.w3.org/2000/01/rdf-schema#label') . '&object=' . uri_escape_utf8('"Testing with longer URI."@en'));
		isa_ok($response, 'Plack::Response');
		is($response->status, 200, "Returns 200");
		my $retmodel = return_model($response->content, $parser);
		has_literal('Testing with longer URI.', 'en', undef, $retmodel, "Longer test phrase is in content");
		has_literal("1", undef, $ns->xsd->integer->as_string, $retmodel, 'Triple count is correct');
		hasnt_literal('This is a test', 'en', undef, $retmodel, "Test phrase isn't in content");
	}
	{
		my $response = $ld->response($base_uri . '/fragments?object=' . uri_escape_utf8('"42"^^http://www.w3.org/2001/XMLSchema#integer'));
		isa_ok($response, 'Plack::Response');
		is($response->status, 200, "Returns 200");
		my $retmodel = return_model($response->content, $parser);
		has_literal('42', undef, $ns->xsd->integer->as_string, $retmodel, "The Answer is in the content");
		has_literal("1", undef, $ns->xsd->integer->as_string, $retmodel, 'Triple count is correct');
		hasnt_literal('This is a test', 'en', undef, $retmodel, "Test phrase isn't in content");
	}
	{
		my $response = $ld->response($base_uri . '/fragments?predicate=' . uri_escape_utf8('http://www.w3.org/2000/01/rdf-schema#label') . '&object=' . uri_escape_utf8('"Nothing here."'));
		isa_ok($response, 'Plack::Response');
		is($response->status, 200, "Returns 200");
		my $retmodel = return_model($response->content, $parser);
		hasnt_literal('Testing with longer URI.', 'en', undef, $retmodel, "Longer test phrase is in content");
		has_literal("0", undef, $ns->xsd->integer->as_string, $retmodel, 'Triple count is correct');
	}
	{
		my $response = $ld->response($base_uri . '/fragments?predicate=' . uri_escape_utf8('http://www.w3.org/2000/01/rdf-schema#label') . '&subject=');
		isa_ok($response, 'Plack::Response');
		is($response->status, 200, "Returns 200");
		my $retmodel = return_model($response->content, $parser);
		has_subject($base_uri . '/foo', $retmodel, 'Subject 1 is correct');
		has_subject($base_uri . '/bar/baz/bing', $retmodel, 'Subject 2 is correct');
		has_literal("2", undef, $ns->xsd->integer->as_string, $retmodel, 'Triple count is correct');
		has_literal('This is a test', 'en', undef, $retmodel, "Test phrase is in content");
	}
	{
		my $response = $ld->response($base_uri . '/fragments?subject=&predicate=&object=');	
		isa_ok($response, 'Plack::Response');
		is($response->status, 200, "Returns 200 with all parameters empty");
	}
	{
		my $response = $ld->response($base_uri . '/fragments');	
		isa_ok($response, 'Plack::Response');
		is($response->status, 200, "Returns 200 with all parameters missing");
		my $retmodel = return_model($response->content, $parser);
		has_predicate('http://www.w3.org/ns/hydra/core#next', $retmodel, 'Has hydra:next predicate');
		has_object_uri($base_uri . '/fragments?allow_dump_dataset=1', $retmodel, '...and object with ? to find the rest');
	}
	{
		my $response = $ld->response($base_uri . '/fragments?predicate=&object=');	
		isa_ok($response, 'Plack::Response');
		is($response->status, 200, "Returns 200 with subject missing other parameters empty");
		my $retmodel = return_model($response->content, $parser);
		has_predicate('http://www.w3.org/ns/hydra/core#next', $retmodel, 'Has hydra:next predicate');
		has_object_uri($base_uri . '/fragments?allow_dump_dataset=1', $retmodel, '...and object with & to find the rest');
	}
}


{
	note 'Testing the Void for fragments';
	
	my $ld = RDF::LinkedData->new(model => $model, base_uri=>$base_uri, 
											fragments_config => $ec, 
											void_config => { urispace => 'http://localhost' });
	isa_ok($ld, 'RDF::LinkedData');
	
	$ld->request(Plack::Request->new({}));
	my $response = $ld->response($base_uri . '/');
	isa_ok($response, 'Plack::Response');
	is($response->status, 200, "Returns 200");
	my $retmodel = return_model($response->content, $parser);
	has_subject($void_subject->uri_value, $retmodel, "Subject URI in content");
	has_predicate($ns->hydra->search->as_string, $retmodel, 'Hydra search predicate');
	pattern_target($retmodel);
	pattern_ok(
				  statement(
								$void_subject,
								iri($ns->void->triples),
								literal(4, undef, iri($ns->xsd->integer))
							  ),
				  statement(
								$void_subject,
								iri($ns->rdf->type),
								iri($ns->void->Dataset)
							  ),
				  'VoID-specific statements');
	pattern_ok(
				  statement($void_subject,
								iri($ns->rdf->type),
								iri($ns->hydra->Collection)),
				  statement($void_subject,
								iri($ns->hydra->search),
								blank('template')),
				  statement(blank('template'),
								iri($ns->hydra->template),
								literal($base_uri . '/fragments{?subject,predicate,object}')),
				  statement(blank('template'),
				                iri($ns->hydra->mapping),
					  		    blank('subject')),
				  statement(blank('template'),
					  			iri($ns->hydra->mapping),
					  			blank('predicate')),
				  statement(blank('template'),
				                iri($ns->hydra->mapping),
					  		    blank('predicate')),
	              statement(blank('template'),
					            iri($ns->hydra->mapping),
					  		    blank('object')),
				  statement(blank('subject'),
								iri($ns->hydra->property),
								iri($ns->rdf->subject)),
				  statement(blank('subject'),
								iri($ns->hydra->variable),
								literal('subject')),
				  statement(blank('predicate'),
								iri($ns->hydra->property),
								iri($ns->rdf->predicate)),
				  statement(blank('predicate'),
								iri($ns->hydra->variable),
								literal('predicate')),
				  statement(blank('object'),
								iri($ns->hydra->property),
								iri($ns->rdf->object)),
				  statement(blank('object'),
								iri($ns->hydra->variable),
								literal('object')),
				  "Control statements OK");
}

{
	note 'Testing the allow_dump_dataset feature with config param';

	my $ld = RDF::LinkedData->new(model => $model,
											base_uri => $base_uri, 
											namespaces_as_vocabularies => 1, 
											void_config => { urispace => 'http://localhost' }, 
											fragments_config => { %$ec , allow_dump_dataset => 1 }
										  );

	isa_ok($ld, 'RDF::LinkedData');

	$ld->request(Plack::Request->new({}));

	{
		my $response = $ld->response($base_uri . '/fragments?subject=&predicate=&object=');	
		isa_ok($response, 'Plack::Response');
		is($response->status, 200, "Returns 200 with all parameters empty");
		my $retmodel = return_model($response->content, $parser);
		has_literal("4", undef, $ns->xsd->integer->as_string, $retmodel, 'Triple count is correct got all 4 triples');
	}
}

{
	note 'Testing the allow_dump_dataset feature with hypermedia';

	my $ld = RDF::LinkedData->new(model => $model,
											base_uri => $base_uri, 
											namespaces_as_vocabularies => 1, 
											void_config => { urispace => 'http://localhost' }, 
											fragments_config => { %$ec }
										  );

	isa_ok($ld, 'RDF::LinkedData');

	$ld->request(Plack::Request->new({}));

	{
		my $response = $ld->response($base_uri . '/fragments?subject=&predicate=&object=');	
		isa_ok($response, 'Plack::Response');
		is($response->status, 200, "Returns 200 with all parameters empty");
		my $retmodel1 = return_model($response->content, $parser);
		has_literal("4", undef, $ns->xsd->integer->as_string, $retmodel1, 'Triple count is correct got all 4 triples');
		my $size1 = $retmodel1->size;
		is($size1, 20, 'Returned triples contain only controls and metadata');
		has_predicate('http://www.w3.org/ns/hydra/core#next', $retmodel1, 'Has hydra:next predicate');
		has_object_uri($base_uri . '/fragments?allow_dump_dataset=1', $retmodel1, '...and object to find the rest');
		my $response2 = $ld->response($base_uri . '/fragments?allow_dump_dataset=1');	
		isa_ok($response, 'Plack::Response');
		is($response->status, 200, "Returns 200 with all parameters empty");
		my $retmodel2 = return_model($response2->content, $parser);
		has_literal("4", undef, $ns->xsd->integer->as_string, $retmodel2, 'Triple count is correct got all 4 triples');
		cmp_ok($size1 + 4 - 1 , '==', $retmodel2->size, 'Size is now three more (+data, -hydra:next)');
		cmp_ok($size1, '<', $retmodel2->size, 'Size is now larger');
		hasnt_uri('http://www.w3.org/ns/hydra/core#next', $retmodel2, 'Hasnt hydra:next predicate');
	}
}




sub return_model {
	my ($content, $parser) = @_;
	my $retmodel = RDF::Trine::Model->temporary_model;
	$parser->parse_into_model( $base_uri, $content, $retmodel );
	return $retmodel;
}


done_testing;
