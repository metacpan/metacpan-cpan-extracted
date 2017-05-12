use lib "lib";
use RDF::Trine::Iterator qw[sgrep];
use RDF::TrineShortcuts;
use RDF::Closure qw[mk_filter FLT_BORING FLT_NONRDF];

my $g = rdf_parse(<<'TURTLE', type=>'turtle');
@prefix rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix owl:  <http://www.w3.org/2002/07/owl#> .
@prefix xsd:  <http://www.w3.org/2001/XMLSchema#> .
@prefix ex:   <http://example.com/> .

ex:son
	rdfs:subPropertyOf ex:child ;
	rdfs:range ex:Male .
ex:Alice rdfs:label "Alice"^^xsd:string ; ex:son ex:Bob .
ex:Robert owl:sameAs ex:Bob ; rdfs:label "Robert"^^xsd:string .
ex:Bob rdfs:label "Robert" .
ex:child a owl:AsymmetricProperty ; rdfs:domain ex:Person ; rdfs:range ex:Person .
ex:Carol ex:child ex:Dave .
ex:Dave ex:child ex:Carol .

ex:grandchild owl:propertyChainAxiom (ex:child ex:child) .
ex:child rdfs:subPropertyOf ex:descendent .
ex:descendent a owl:TransitiveProperty .
ex:Bob ex:child ex:Fey .

ex:parent owl:inverseOf ex:child ; rdfs:domain ex:Person ; rdfs:range ex:Person .
ex:Robert ex:mother ex:Ali , ex:Alice .
ex:mother rdfs:subPropertyOf ex:parent ; rdfs:range ex:Female .
ex:Person rdfs:subClassOf [ a owl:Restriction; owl:onProperty ex:mother ; owl:maxCardinality 1 ] .
# should be able to infer that { ex:Ali owl:sameAs ex:Alice . }
ex:Ali ex:age "29"^^xsd:integer , "29.0"^^xsd:decimal , "29/1"^^owl:rational .

ex:Person owl:hasKey (ex:forename ex:surname) ; rdfs:subClassOf [ a owl:Restriction ; owl:hasSelf true; owl:onProperty ex:knows ] .
ex:Dave ex:forename "David" ; ex:surname "Jones" .
ex:David a ex:Person; ex:forename "David" ; ex:surname "Jones" .
ex:Robert ex:forename "Bob"^^xsd:string .

ex:ShortNamedPerson
	rdfs:subClassOf ex:Person ,
		[
			a owl:Restriction ;
			owl:onProperty ex:forename ;
			owl:someValuesFrom
				[
					a rdfs:Datatype ;
					owl:onDatatype xsd:string ;
					owl:withRestrictions (
						[ xsd:minLength 1 ]
						[ xsd:maxLength 3 ]
					)
				]
		] .

TURTLE

my $cl = RDF::Closure::Engine->new('OWL2Plus', $g);
$cl->closure;

#my $filter = mk_filter(FLT_NONRDF|FLT_BORING, [$cl->{error_context}]);
#my $stream = &sgrep($filter, $cl->graph->as_stream);

print rdf_string($g => 'turtle', namespaces=>{
	rdf  => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
	rdfs => 'http://www.w3.org/2000/01/rdf-schema#',
	owl  => 'http://www.w3.org/2002/07/owl#',
	xsd  => 'http://www.w3.org/2001/XMLSchema#',
	ex   => 'http://example.com/',
	});
