use Test::More tests => 15;
use OWL::DirectSemantics;
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

my $input = <<'INPUT';
@prefix :     <http://www.example.com/> .
@prefix rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix owl:  <http://www.w3.org/2002/07/owl#> .
@prefix xsd:  <http://www.w3.org/2001/XMLSchema#> .
@prefix foaf: <http://xmlns.com/foaf/0.1/> .

foaf:Person a owl:Class.
foaf:name a owl:DatatypeProperty.

:Bob a foaf:Person; foaf:name "Bob".
INPUT

my $model = RDF::Trine::Model->new;
RDF::Trine::Parser
	-> new('Turtle')
	-> parse_into_model('http://www.example.com/', $input, $model);

my $translator = new_ok 'OWL::DirectSemantics::Translator';
my $ontology   = $translator->translate($model);
isa_ok $ontology, 'OWL::DirectSemantics::Element::Ontology';

my ($bob_type, $bob_name, $foaf_person, $foaf_name) =
	my @debug = 
	sort {
		ref($a)          cmp ref($b)          or
		ref($a->declare) cmp ref($b->declare)
	}
	$ontology->axioms;

#note explain($_->fs) for @debug;

is(
	$bob_type->element_name => 'ClassAssertion',
	'Found a ClassAssertion',
);
ok($bob_type->node->equal($EX->Bob));
ok($bob_type->class->equal($FOAF->Person));

is(
	$bob_name->element_name => 'DataPropertyAssertion',
	'Found a DataPropertyAssertion',
);
ok($bob_name->s->equal($EX->Bob));
ok($bob_name->p->equal($FOAF->name));
ok($bob_name->o->equal(literal('Bob')));

is(
	$foaf_person->element_name => 'Declaration',
	'Found a Declaration',
);
is(
	$foaf_person->declare->element_name => 'Class',
	'Declared a Class',
);
ok($foaf_person->declare->node->equal($FOAF->Person));

is(
	$foaf_name->element_name => 'Declaration',
	'Found a Declaration',
);
is(
	$foaf_name->declare->element_name => 'DataProperty',
	'Declared a DataProperty',
);
ok($foaf_name->declare->node->equal($FOAF->name));

note($ontology->fs);
