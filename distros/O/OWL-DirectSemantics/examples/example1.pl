use lib "lib";
use RDF::Trine::Model;
use Data::Printer;
use OWL::DirectSemantics;
use RDF::TrineShortcuts;

my $model = rdf_parse(<<'TURTLE', type=>'turtle');

@prefix rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix owl:  <http://www.w3.org/2002/07/owl#> .
@prefix xsd:  <http://www.w3.org/2001/XMLSchema#> .
@prefix ex: <http://example.com/> . 

ex: a owl:Ontology ;
	rdfs:label "This Ontology" ;
	owl:imports ex:ont1 , ex:ont2 .

rdfs:label a owl:AnnotationProperty .

ex:Bob a owl:NamedIndividual, ex:Person ;
	ex:name "Bob" .

ex:Person a owl:Class .
[ a owl:Axiom ]
	rdfs:comment "ex:Person is an owl:Class" ;
	owl:annotatedSource ex:Person ;
	owl:annotatedProperty rdf:type ;
	owl:annotatedTarget owl:Class .

ex:name a owl:DatatypeProperty ;
	rdfs:range [
		a rdfs:Datatype ;
		owl:intersectionOf (xsd:string rdf:PlainLiteral)
		] .

ex:evil_act a owl:ObjectProperty .
ex:NicePerson a owl:Class ;
	rdfs:subClassOf ex:Person ;
	rdfs:subClassOf [
		a owl:Restriction ;
		owl:onProperty ex:evil_act ;
		owl:cardinality "0"^^xsd:nonNegativeInteger
		] .
ex:Human a owl:Class ; owl:equivalentClass ex:Person .
ex:Flea a owl:Class ; owl:disjointWith ex:Human .

xsd:string a rdfs:Datatype .

ex:string a rdfs:Datatype; owl:equivalentClass xsd:string .

ex:label a owl:DatatypeProperty , owl:FunctionalProperty ;
	owl:equivalentProperty ex:name .

rdf:PlainLiteral a rdfs:Datatype .

ex:Bob owl:sameAs ex:Robert .

TURTLE

print "################\n";
print rdf_string($model => 'turtle');
print "################\n";
my $translator = OWL::DirectSemantics::Translator->new;
my $ontology   = $translator->translate($model);
print p $ontology;
print "################\n";
print $ontology->dump;
print "################\n";
print $ontology->fs;
print "################\n";
print rdf_string($model => 'turtle');
print "################\n";

