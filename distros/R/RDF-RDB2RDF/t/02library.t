use 5.008;
use strict;
use Test::More tests => 15;

BEGIN { use_ok( 'RDF::RDB2RDF::R2RML' ); }

use RDF::Trine qw[iri literal];

my $rdb2rdf = new_ok('RDF::RDB2RDF::R2RML' => [<<'TURTLE'], 'Mapping');
@prefix rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix owl:  <http://www.w3.org/2002/07/owl#> .
@prefix xsd:  <http://www.w3.org/2001/XMLSchema#> .
@prefix rr:   <http://www.w3.org/ns/r2rml#>.
@prefix rrx:  <http://purl.org/r2rml-ext/>.
@prefix exa:  <http://example.com/core#>.
@prefix dept: <http://example.com/dept#>.
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix bibo: <http://purl.org/ontology/bibo/> .
@prefix dc:   <http://purl.org/dc/terms/> .
@prefix skos: <http://www.w3.org/2004/02/skos/core#> .

[]
	a rr:TriplesMap;
	rr:logicalTable [ rr:tableName "books" ];

	rr:subjectMap [ rr:template "http://example.com/id/book/{book_id}";
	                rr:termType "IRI";
	                rr:class bibo:Book; 
	                rr:graph exa:BookGraph ];

	rr:predicateObjectMap
	[ 
		rr:predicate rdfs:label; 
		rr:predicateMap [ rr:constant dc:title ]; 
		rr:objectMap    [ rr:column "title"; rr:language "en" ]
	] ;

	rr:predicateObjectMap
	[
		rr:predicate dc:identifier ;
		rr:objectMap [ rr:column "book_id" ; rr:termtype "literal" ]
	]
.

[]
	a rr:TriplesMap;
	
	rr:logicalTable [ rr:sqlQuery """
	
		SELECT *, forename||' '||surname AS fullname
		FROM authors
		
	""" ] ;

	rr:subjectMap [ rr:template "http://example.com/id/author/{author_id}";
	                rr:termType "IRI";
	                rr:class foaf:Person; 
	                rr:graph exa:AuthorGraph ];

	rr:predicateObjectMap
	[ 
		rr:predicateMap [ rr:constant foaf:givenName ]; 
		rr:objectMap    [ rr:column "forename" ; rr:termtype "litERAl" ]
	];
	
	rr:predicateObjectMap
	[
		rr:predicate rdf:type ;
		rr:object exa:Author
	];

	rr:predicateObjectMap
	[ 
		rr:predicateMap [ rr:constant foaf:familyName ]; 
		rr:objectMap    [ rr:column "surname" ; rr:termType rr:Literal ]
	];

	rr:predicateObjectMap
	[ 
		rr:predicateMap [ rr:constant foaf:name ] ; 
		rr:predicateMap [ rr:constant rdfs:label  ]; 
		rr:objectMap    [ rr:column "fullname" ; rr:termType "literaL" ]
	]
.

[]
	a rr:TriplesMap;
	rr:tableName "topics";

	rr:subjectMap [ rr:template "http://example.com/id/topic/{topic_id}" ;
	                rr:class skos:Concept ; 
	                rr:graph exa:ConceptGraph ];

	rr:predicateObjectMap
	[
		rr:predicateMap [ rr:constant rdfs:label ]; 
		rr:predicateMap [ rr:constant skos:prefLabel ]; 
		rr:objectMap    [ rr:column "label"; rr:language "en" ]
	]
.

[]
	a rr:TriplesMap;
	rr:tableName "book_authors";

	rr:subjectMap [ rr:template "http://example.com/id/book/{book_id}" ;
	                rr:graph exa:BookGraph ];

	rr:predicateObjectMap
	[
		rr:predicateMap [ rr:constant foaf:maker ]; 
		rr:predicateMap [ rr:constant bibo:author ]; 
		rr:predicateMap [ rr:constant dc:creator ]; 
		rr:objectMap    [ rr:template "http://example.com/id/author/{author_id}"; rr:termType "IRI" ]
	]
.

[]
	a rr:TriplesMap;
	rr:tableName "book_authors";

	rr:subjectMap [ rr:template "http://example.com/id/author/{author_id}" ;
	                rr:graph exa:BookGraph ];

	rr:predicateObjectMap
	[
		rr:predicateMap [ rr:constant foaf:made ]; 
		rr:objectMap    [ rr:template "http://example.com/id/book/{book_id}"; rr:termType "IRI" ]
	]
.

[]
	a rr:TriplesMap;
	rr:tableName "book_topics";

	rr:subjectMap [ rr:template "http://example.com/id/book/{book_id}" ;
	                rr:graph exa:BookGraph ];

	rr:predicateObjectMap
	[
		rr:predicateMap [ rr:constant dc:subject ]; 
		rr:objectMap    [ rr:template "http://example.com/id/topic/{topic_id}"; rr:termType "IRI" ]
	]
.


TURTLE

can_ok($rdb2rdf, 'process');
can_ok($rdb2rdf, 'process_turtle');
can_ok($rdb2rdf, 'to_json');
can_ok($rdb2rdf, 'to_hashref');

my %ns = $rdb2rdf->namespaces;
is($ns{dc}->FOO->uri, 'http://purl.org/dc/terms/FOO', 'namespaces look right');

my $mappings = $rdb2rdf->mappings;
is($mappings->{books}{about}, "http://example.com/id/book/{book_id}", 'mapping looks right');

my $dbh   = DBI->connect("dbi:SQLite:dbname=t/library.sqlite");
my $model = $rdb2rdf->process($dbh);

isa_ok($model, 'RDF::Trine::Model', 'Output');

is($model->count_statements(
		iri('http://example.com/id/book/3'),
		iri('http://purl.org/dc/terms/title'),
		literal('Zen and the Art of Motorcycle Maintenance: An Inquiry into Values', 'en'),
		), 1,
	'Simple literal triple output.'
	);

is($model->count_statements(
		iri('http://example.com/id/book/3'),
		iri('http://purl.org/dc/terms/identifier'),
		literal(3, undef, 'http://www.w3.org/2001/XMLSchema#integer')
		), 1,
	'SQL datatypes are picked up correctly.'
	);

is($model->count_statements(
		iri('http://example.com/id/book/3'),
		iri('http://purl.org/dc/terms/creator'),
		iri('http://example.com/id/author/2'),
		), 1,
	'Simple non-literal triple output.'
	);

is($model->count_statements(
		iri('http://example.com/id/author/2'),
		iri('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
		iri('http://xmlns.com/foaf/0.1/Person'),
		), 1,
	'Simple class triple output.'
	);

is($model->count_statements(
		iri('http://example.com/id/book/3'),
		iri('http://www.w3.org/2000/01/rdf-schema#label'),
		literal('Zen and the Art of Motorcycle Maintenance: An Inquiry into Values', 'en'),
		), 1,
	'rr:predicate shortcut property'
	);

is($model->count_statements(
		iri('http://example.com/id/author/2'),
		iri('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
		iri('http://example.com/core#Author'),
		), 1,
	'rr:object shortcut property'
	);


# print $rdb2rdf->process_turtle($dbh);
