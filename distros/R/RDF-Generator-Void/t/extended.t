use Test::More;
use Test::RDF;
use FindBin qw($Bin);
use URI;
use RDF::Trine qw(literal statement iri variable);
use RDF::Trine::Parser;
use RDF::Trine::Namespace qw(rdf owl foaf rdfs rel dc);
use utf8;


my $builder = Test::More->builder;
binmode $builder->output, ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output, ":utf8";

my $base_uri = 'http://localhost';

my $testdata = $Bin . '/data/generated.ttl';
my $expected = $Bin . '/data/generated-expected.ttl';

use_ok("RDF::Generator::Void");

diag 'These tests take a fair amount of resources';

my $expected_void_model = RDF::Trine::Model->temporary_model;
my $data_model = RDF::Trine::Model->temporary_model;

my $parser     = RDF::Trine::Parser->new( 'turtle' );

$parser->parse_file_into_model( $base_uri, $testdata, $data_model );

my $void_gen = RDF::Generator::Void->new(dataset_uri => 'http://example.org/',
													  inmodel => $data_model);
$void_gen->urispace('http://example.org/subjects/');

isa_ok($void_gen, 'RDF::Generator::Void');

my $test_model = $void_gen->generate;

my $void = RDF::Trine::Namespace->new('http://rdfs.org/ns/void#');
my $xsd = RDF::Trine::Namespace->new('http://www.w3.org/2001/XMLSchema#');

pattern_target($test_model);

pattern_ok(statement(iri('http://example.org/'), $void->triples,
								 literal(4667, undef, $xsd->integer)), 'Triples OK');

pattern_ok(statement(iri('http://example.org/'), $void->entities,
								 literal(558, undef, $xsd->integer)), 'Entities OK');

pattern_ok(
			  statement(iri('http://example.org/'), $void->properties,
								 literal(17, undef, $xsd->integer)),
			  statement(iri('http://example.org/'), $void->distinctObjects,
								 literal(3525, undef, $xsd->integer)),
			  statement(iri('http://example.org/'), $void->distinctSubjects,
								 literal(756, undef, $xsd->integer)),
			  'Rest of basic counts OK');

pattern_ok(statement(iri('http://example.org/'), $void->propertyPartition, variable('propart')),
			  statement(variable('propart'), $void->property, iri('http://purl.org/dc/terms/date')),
			  statement(variable('propart'), $void->triples, literal(298, undef, $xsd->integer)),
			  statement(variable('propart'), $void->distinctObjects, literal(293, undef, $xsd->integer)),
			  statement(variable('propart'), $void->distinctSubjects, literal(298, undef, $xsd->integer)),
  'dc:date properties OK');

pattern_ok(statement(iri('http://example.org/'), $void->propertyPartition, variable('propart')),
			  statement(variable('propart'), $void->property, iri('http://purl.org/vocab/relationship/apprenticeTo')),
			  statement(variable('propart'), $void->triples, literal(198, undef, $xsd->integer)),
			  statement(variable('propart'), $void->distinctObjects, literal(188, undef, $xsd->integer)),
			  statement(variable('propart'), $void->distinctSubjects, literal(168, undef, $xsd->integer)),
 'rel:apprenticeTo properties OK');

pattern_ok(statement(iri('http://example.org/'), $void->classPartition, variable('classpart')),
			  statement(variable('classart'), $void->class, iri('http://purl.org/dc/terms/Event')),
			  statement(variable('classart'), $void->triples, literal(112, undef, $xsd->integer)),
  'dc:Event classes OK');



$parser->parse_file_into_model( $base_uri, $expected, $expected_void_model );

SKIP: {
	skip "There are weird performance bugs here", 1 unless $ENV{SLOW_TESTS};
	are_subgraphs($expected_void_model, $test_model, 'Got the expected VoID description with generated data');
}

use RDF::Trine::Serializer;
my $ser = RDF::Trine::Serializer->new('turtle', namespaces => {dc => $dc, rdf => $rdf, rdfs => $rdfs, owl => $owl, foaf => $foaf, xsd => $xsd, rel => $rel, void => iri('http://rdfs.org/ns/void#')});
#note $ser->serialize_model_to_string($test_model);

done_testing;
