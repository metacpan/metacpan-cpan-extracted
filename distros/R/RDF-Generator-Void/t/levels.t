use Test::More;
use Test::RDF 1.10;
use FindBin qw($Bin);
use URI;
use RDF::Trine qw(literal statement iri variable);
use RDF::Trine::Parser;

my $base_uri = 'http://localhost';

my $testdata = $Bin . '/data/basic.ttl';
my $expected = $Bin . '/data/basic-expected.ttl';

use_ok("RDF::Generator::Void");

my $expected_void_model = RDF::Trine::Model->temporary_model;
my $data_model = RDF::Trine::Model->temporary_model;

my $parser     = RDF::Trine::Parser->new( 'turtle' );
$parser->parse_file_into_model( $base_uri, $testdata, $data_model );

my $void = RDF::Trine::Namespace->new('http://rdfs.org/ns/void#');
my $xsd = RDF::Trine::Namespace->new('http://www.w3.org/2001/XMLSchema#');

note "No level set";
{
	my $void_gen = RDF::Generator::Void->new(dataset_uri => $base_uri . '/dataset',
														  inmodel => $data_model);
	$void_gen->urispace($base_uri);
	isa_ok($void_gen, 'RDF::Generator::Void');
	my $test_model = $void_gen->generate;
	isa_ok($test_model, 'RDF::Trine::Model');

	note(RDF::Trine::Serializer::Turtle->new->serialize_model_to_string($test_model));

	has_predicate('http://rdfs.org/ns/void#triples', $test_model, 'Has got the triples predicate');
	has_predicate('http://rdfs.org/ns/void#entities', $test_model, 'Has got the entities predicate');
	has_predicate('http://rdfs.org/ns/void#classPartition', $test_model, 'Has got the classPartition predicate');
	pattern_target($test_model);
	pattern_ok(statement(iri($base_uri . '/dataset'), $void->propertyPartition, variable('propart')),
			  statement(variable('propart'), $void->property, iri('http://www.w3.org/2000/01/rdf-schema#label')),
			  statement(variable('propart'), $void->triples, literal(2, undef, $xsd->integer)),
			  statement(variable('propart'), $void->distinctObjects, literal(2, undef, $xsd->integer)),
			  statement(variable('propart'), $void->distinctSubjects, literal(2, undef, $xsd->integer)),
  'rdfs:label propertyPartitions OK');

}

note "Level set to 0";
{
	my $void_gen = RDF::Generator::Void->new(dataset_uri => $base_uri . '/dataset',
														  inmodel => $data_model, level => 0);
	$void_gen->urispace($base_uri);
	isa_ok($void_gen, 'RDF::Generator::Void');
	my $test_model = $void_gen->generate;
	isa_ok($test_model, 'RDF::Trine::Model');

	note(RDF::Trine::Serializer::Turtle->new->serialize_model_to_string($test_model));

	has_predicate('http://rdfs.org/ns/void#triples', $test_model, 'Has got the triples predicate');
	hasnt_uri('http://rdfs.org/ns/void#entities', $test_model, 'Hasnt got the entities predicate');
	hasnt_uri('http://rdfs.org/ns/void#classPartition', $test_model, 'Hasnt got the classPartition predicate');
	hasnt_uri('http://rdfs.org/ns/void#propertyPartition', $test_model, 'Hasnt got the propertyPartition predicate');
	hasnt_uri('http://rdfs.org/ns/void#distinctObjects', $test_model, 'Hasnt got the distinctObjects predicate');

}


note "Level set to 1";
{
	my $void_gen = RDF::Generator::Void->new(dataset_uri => $base_uri . '/dataset',
														  inmodel => $data_model, level => 1);
	$void_gen->urispace($base_uri);
	isa_ok($void_gen, 'RDF::Generator::Void');
	my $test_model = $void_gen->generate;
	isa_ok($test_model, 'RDF::Trine::Model');

	note(RDF::Trine::Serializer::Turtle->new->serialize_model_to_string($test_model));

	has_predicate('http://rdfs.org/ns/void#triples', $test_model, 'Has got the triples predicate');
	has_predicate('http://rdfs.org/ns/void#entities', $test_model, 'Has got the entities predicate');
	hasnt_uri('http://rdfs.org/ns/void#classPartition', $test_model, 'Hasnt got the classPartition predicate');
	hasnt_uri('http://rdfs.org/ns/void#propertyPartition', $test_model, 'Hasnt got the propertyPartition predicate');
	has_predicate('http://rdfs.org/ns/void#distinctObjects', $test_model, 'Has got the distinctObjects predicate');
	pattern_target($test_model);
	pattern_fail(statement(iri($base_uri . '/dataset'), $void->propertyPartition, variable('propart')),
			  statement(variable('propart'), $void->property, iri('http://www.w3.org/2000/01/rdf-schema#label')),
			  statement(variable('propart'), $void->triples, variable('whatever1')),
			  statement(variable('propart'), $void->distinctObjects, variable('whatever2')),
			  statement(variable('propart'), $void->distinctSubjects, variable('whatever3')),
  'rdfs:label propertyPartitions not present');

}

note "Level set to 2";
{
	my $void_gen = RDF::Generator::Void->new(dataset_uri => $base_uri . '/dataset',
														  inmodel => $data_model, level => 2);
	$void_gen->urispace($base_uri);
	isa_ok($void_gen, 'RDF::Generator::Void');
	my $test_model = $void_gen->generate;
	isa_ok($test_model, 'RDF::Trine::Model');

	note(RDF::Trine::Serializer::Turtle->new->serialize_model_to_string($test_model));

	has_predicate('http://rdfs.org/ns/void#triples', $test_model, 'Has got the triples predicate');
	has_predicate('http://rdfs.org/ns/void#entities', $test_model, 'Has got the entities predicate');
	has_predicate('http://rdfs.org/ns/void#classPartition', $test_model, 'Has got the classPartition predicate');
	pattern_target($test_model);
	pattern_ok(statement(iri($base_uri . '/dataset'), $void->propertyPartition, variable('propart')),
			  statement(variable('propart'), $void->property, iri('http://www.w3.org/2000/01/rdf-schema#label')),
			  statement(variable('propart'), $void->triples, literal(2, undef, $xsd->integer)),
  'rdfs:label propertyPartitions OK');
	pattern_fail(statement(iri($base_uri . '/dataset'), $void->propertyPartition, variable('propart')),
			  statement(variable('propart'), $void->property, iri('http://www.w3.org/2000/01/rdf-schema#label')),
			  statement(variable('propart'), $void->distinctObjects, variable('whatever1')),
			  statement(variable('propart'), $void->distinctSubjects, variable('whatever2')),
  'rdfs:label propertyPartitions without distinct* not present');

}

note "Level set to 3";
{
	my $void_gen = RDF::Generator::Void->new(dataset_uri => $base_uri . '/dataset',
														  inmodel => $data_model, level => 3);
	$void_gen->urispace($base_uri);
	isa_ok($void_gen, 'RDF::Generator::Void');
	my $test_model = $void_gen->generate;
	isa_ok($test_model, 'RDF::Trine::Model');

	note(RDF::Trine::Serializer::Turtle->new->serialize_model_to_string($test_model));

	has_predicate('http://rdfs.org/ns/void#triples', $test_model, 'Has got the triples predicate');
	has_predicate('http://rdfs.org/ns/void#entities', $test_model, 'Has got the entities predicate');
	has_predicate('http://rdfs.org/ns/void#classPartition', $test_model, 'Has got the classPartition predicate');
	pattern_target($test_model);
	pattern_ok(statement(iri($base_uri . '/dataset'), $void->propertyPartition, variable('propart')),
			  statement(variable('propart'), $void->property, iri('http://www.w3.org/2000/01/rdf-schema#label')),
			  statement(variable('propart'), $void->triples, literal(2, undef, $xsd->integer)),
			  statement(variable('propart'), $void->distinctObjects, literal(2, undef, $xsd->integer)),
			  statement(variable('propart'), $void->distinctSubjects, literal(2, undef, $xsd->integer)),
  'rdfs:label propertyPartitions OK');

}



done_testing;
