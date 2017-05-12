use strict;
use warnings;
use Test::More;

use DBI;
use RDF::RDB2RDF;
use RDF::Trine 'iri', 'literal';

my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:');

$dbh->do("CREATE TABLE codes (
	objectproperty text,
	subpropertyof  text,
	concept        text,
	label          text,
	label_lang     text
)");

$dbh->do("INSERT INTO codes VALUES (
	'http://example.com/ontology/broaderGeneric',
	'http://www.w3.org/2004/02/skos/core#broader',
	'http://example.com/Thingy1',
	'Broader Generic',
	'en'
)");

$dbh->do("INSERT INTO codes VALUES (
	'http://example.com/ontology/historicFlag',
	'http://example.com/Thingy2',
	'http://example.com/Thingy3',
	'Historic flag',
	'en'
)");

$dbh->do("INSERT INTO codes VALUES (
	'http://example.com/Thingy4',
	'http://example.com/Thingy5',
	'http://example.com/thesaurus/historic/Current',
	'Current',
	NULL
)");

my $mapper = RDF::RDB2RDF->new('R2RML', <<'R2RML');

@prefix rr:    <http://www.w3.org/ns/r2rml#>.
@prefix rrx:   <http://purl.org/r2rml-ext/>.
@prefix rdfs:  <http://www.w3.org/2000/01/rdf-schema#>.
@prefix owl:   <http://www.w3.org/2002/07/owl#>.
@prefix skos:  <http://www.w3.org/2004/02/skos/core#>.

<#ObjectPropertyMap>
  rr:logicalTable [rr:tableName "CODES"];
  rr:subjectMap [rr:class owl:ObjectProperty; rr:column "ObjectProperty"];
  rr:predicateObjectMap [rr:predicate rdfs:subPropertyOf; rr:objectMap [rr:column "subPropertyOf"; rr:termType rr:IRI]];
  rr:predicateObjectMap [rr:predicate rdfs:label; rr:objectMap [rr:column "label"; rrx:languageColumn "label_lang"]].

<#ConceptMap>
  rr:logicalTable [rr:tableName "CODES"];
  rr:subjectMap [rr:class skos:Concept; rr:column "Concept"];
  rr:predicateObjectMap [rr:predicate skos:prefLabel; rr:objectMap [rr:column "label"; rr:language "xx"; rrx:languageColumn "label_lang"]].

R2RML

my $result = $mapper->process($dbh);

ok(
	$result->count_statements(
		iri(q<http://example.com/Thingy1>),
		iri(q<http://www.w3.org/2004/02/skos/core#prefLabel>),
		literal('Broader Generic', 'en'),
	),
	'language from lang_column',
);

ok(
	$result->count_statements(
		iri(q<http://example.com/thesaurus/historic/Current>),
		iri(q<http://www.w3.org/2004/02/skos/core#prefLabel>),
		literal('Current', 'xx'),
	),
	'language from lang_column is null; uses fallback',
);

ok(
	$result->count_statements(
		iri(q<http://example.com/Thingy4>),
		iri(q<http://www.w3.org/2000/01/rdf-schema#label>),
		literal('Current'),
	),
	'language from lang_column is null; no fallback',
);

done_testing;
