use Test::More tests => 4;
use Test::RDF;
use RDF::Closure;
use RDF::Trine qw(statement iri literal blank variable);

my ($EX, $RDF, $RDFS, $OWL, $XSD, $FOAF) =
	do {
		no warnings;
		map { RDF::Trine::Namespace->new($_) }
		qw {
			http://www.example.com/
			http://www.w3.org/1999/02/22-rdf-syntax-ns#
			http://www.w3.org/2000/01/rdf-schema#
			http://www.w3.org/2002/07/owl#
			http://www.w3.org/2001/XMLSchema#
			http://xmlns.com/foaf/0.1/
		}
	};

my $ser = RDF::Trine::Serializer->new(
	'Turtle',
	namespaces => {
		ex   =>   $EX->uri->uri,
		rdf  =>  $RDF->uri->uri,
		owl  =>  $OWL->uri->uri,
		xsd  =>  $XSD->uri->uri,
		foaf => $FOAF->uri->uri,
		rdfs =>  $RDF->uri->uri,
	},
);

my $input = <<'INPUT';
@prefix :     <http://www.example.com/> .
@prefix rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix owl:  <http://www.w3.org/2002/07/owl#> .
@prefix xsd:  <http://www.w3.org/2001/XMLSchema#> .
@prefix foaf: <http://xmlns.com/foaf/0.1/> .

# Mini ontology
foaf:Person rdfs:subClassOf foaf:Agent .
foaf:homepage a owl:InverseFunctionalProperty .

# Some data
:Bob a foaf:Person .
:Bob foaf:homepage <http://bob.example.com/> .
:Robert foaf:homepage <http://bob.example.com/> .
:Robert foaf:age "102/4"^^owl:rational .
INPUT

## Same input data for both
my $turtle_parser = RDF::Trine::Parser->new('Turtle');
my ($m_rdfs, $m_owl2rl) = 
	map {
		my $m = RDF::Trine::Model->new;
		$turtle_parser->parse_into_model('http://www.example.com/', $input, $m);
		$m;
	} 1..2;

## RDFS
RDF::Closure::Engine->new(rdfs => $m_rdfs)->closure;
pattern_target($m_rdfs);

pattern_ok
	statement($EX->Bob, $RDF->type, $FOAF->Agent);

## OWL2RL
RDF::Closure::Engine->new(owl2rl => $m_owl2rl)->closure;
pattern_target($m_owl2rl);

pattern_ok
	statement($EX->Robert, $RDF->type, $FOAF->Agent),
	statement($EX->Robert, $OWL->sameAs, $EX->Bob),	
	statement($EX->Bob, $OWL->sameAs, $EX->Robert);
