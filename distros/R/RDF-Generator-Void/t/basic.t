use Test::More;
use Test::RDF;
use FindBin qw($Bin);
use URI;
use RDF::Trine qw(literal statement iri);
use RDF::Trine::Parser;
use utf8;

my $builder = Test::More->builder;
binmode $builder->output, ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output, ":utf8";

my $base_uri = 'http://localhost';

my $testdata = $Bin . '/data/basic.ttl';
my $expected = $Bin . '/data/basic-expected.ttl';

use_ok("RDF::Generator::Void");

my $expected_void_model = RDF::Trine::Model->temporary_model;
my $data_model = RDF::Trine::Model->temporary_model;

my $parser     = RDF::Trine::Parser->new( 'turtle' );
$parser->parse_file_into_model( $base_uri, $testdata, $data_model );

my $void_gen = RDF::Generator::Void->new(dataset_uri => $base_uri . '/dataset#foo',
													  inmodel => $data_model, level => 1);
$void_gen->urispace($base_uri);

isa_ok($void_gen, 'RDF::Generator::Void');

my $test_model = $void_gen->generate;

isa_ok($test_model, 'RDF::Trine::Model');

$parser->parse_file_into_model( $base_uri, $expected, $expected_void_model );

are_subgraphs($test_model, $expected_void_model, 'Got the expected VoID description with generated data');

$void_gen->add_endpoints($base_uri . '/sparql');

$test_model = $void_gen->generate;

are_subgraphs($test_model, $expected_void_model, 'Got the expected VoID description with SPARQL');
has_uri($base_uri . '/sparql', $test_model, 'Has endpoint URL');



$void_gen->add_titles(literal('This is a title', 'en'), literal('Blåbærsyltetøy', 'nb'));
$test_model = $void_gen->generate;

are_subgraphs($test_model, $expected_void_model, 'Got the expected VoID description with title');
has_literal('This is a title', 'en', undef, $test_model, 'Has title');
has_literal('Blåbærsyltetøy', 'nb', undef, $test_model, 'Has title with UTF8');

$void_gen->add_licenses('http://example.org/open-data-license');

$test_model = $void_gen->generate;

are_subgraphs($test_model, $expected_void_model, 'Got the expected VoID description with license');
has_uri('http://example.org/open-data-license', $test_model, 'Has license URL');


$test_model = $void_gen->generate;

are_subgraphs($test_model, $expected_void_model, 'Got the expected VoID description with urispace');
has_literal($base_uri, undef, undef, $test_model, 'Has urispace');




my $testfinal_model = $void_gen->generate;

#note(RDF::Trine::Serializer::Turtle->new->serialize_model_to_string($testfinal_model));
isomorph_graphs($expected_void_model, $testfinal_model, 'Got the expected complete VoID description');


my $more_model = RDF::Trine::Model->temporary_model;
$more_model->add_statement(statement(iri('http://example.org/open-data-license'),
												 iri('http://www.w3.org/2000/01/rdf-schema#label'),
												 literal('Arbitrary description of license', 'en')));

my $testmore_model = $void_gen->generate($more_model);

are_subgraphs($expected_void_model, $testmore_model, 'Got the expected VoID description which is now a subset');
has_literal('Arbitrary description of license', 'en', undef, $testmore_model, 'Has license literal');
$expected_void_model->add_statement(statement(iri('http://example.org/open-data-license'),
												 iri('http://www.w3.org/2000/01/rdf-schema#label'),
												 literal('Arbitrary description of license', 'en')));

hasnt_uri('http://rdfs.org/ns/void#propertyPartition', $testmore_model, 'Hasnt got the propertyPartitions predicate');
hasnt_uri('http://rdfs.org/ns/void#classPartition', $testmore_model, 'Hasnt got the classPartitions predicate');

isomorph_graphs($expected_void_model, $testmore_model, 'By adding arbitrary triple to expected, these two also becomes isomorph');


done_testing;
