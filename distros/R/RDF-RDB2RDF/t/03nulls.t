use strict;
use warnings;
use Test::More;

use DBI;
use RDF::RDB2RDF;
use RDF::Trine 'iri';

my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:');

$dbh->do("CREATE TABLE codes (
	objectproperty text,
	subpropertyof  text,
	concept        text,
	label          text
)");

$dbh->do("INSERT INTO codes VALUES (
	'http://example.com/ontology/broaderGeneric',
	'http://www.w3.org/2004/02/skos/core#broader',
	NULL,
	'Broader Generic'
)");

$dbh->do("INSERT INTO codes VALUES (
	'http://example.com/ontology/historicFlag',
	NULL,
	NULL,
	'Historic flag'
)");

$dbh->do("INSERT INTO codes VALUES (
	NULL,
	NULL,
	'http://example.com/thesaurus/historic/Current',
	'Current'
)");

my $mapper = RDF::RDB2RDF->new('R2RML', <<'R2RML');

@prefix rr:    <http://www.w3.org/ns/r2rml#>.
@prefix rdfs:  <http://www.w3.org/2000/01/rdf-schema#>.
@prefix owl:   <http://www.w3.org/2002/07/owl#>.
@prefix skos:  <http://www.w3.org/2004/02/skos/core#>.

<#ObjectPropertyMap>
  rr:logicalTable [rr:tableName "CODES"];
  rr:subjectMap [rr:class owl:ObjectProperty; rr:column "ObjectProperty"];
  rr:predicateObjectMap [rr:predicate rdfs:subPropertyOf; rr:objectMap [rr:column "subPropertyOf"; rr:termType rr:IRI]];
  rr:predicateObjectMap [rr:predicate rdfs:label; rr:objectMap [rr:column "label"]].

<#ConceptMap>
  rr:logicalTable [rr:tableName "CODES"];
  rr:subjectMap [rr:class skos:Concept; rr:column "Concept"];
  rr:predicateObjectMap [rr:predicate skos:prefLabel; rr:objectMap [rr:column "label"]].

R2RML

my $result = $mapper->process($dbh);

is(
	$result->count_statements( iri('http://example.com/base/') ),
	0,
);

done_testing;
