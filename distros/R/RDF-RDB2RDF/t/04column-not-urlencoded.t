use strict;
use warnings;
use Test::More;

use RDF::RDB2RDF;
use RDF::Trine qw' literal iri ';

my $dbh    = DBI->connect("dbi:SQLite:dbname=t/library.sqlite");
my $mapper = RDF::RDB2RDF->new('R2RML', <<'R2RML');

@base         <http://id.example.net/>.
@prefix rr:   <http://www.w3.org/ns/r2rml#>.
@prefix rrx:  <http://purl.org/r2rml-ext/>.
@prefix bibo: <http://purl.org/ontology/bibo/>.
@prefix dc:   <http://purl.org/dc/elements/1.1/>.

[] rr:logicalTable [rr:sqlQuery """
    select *, 
      'http://purl.org/dc/elements/1.1/title' as titleProperty
    from books"""];
  rr:subjectMap [rr:class bibo:Book; rr:template "book/{book_id}"];
  rr:predicateObjectMap [
    rr:predicateMap [rr:column "titleProperty"];
    rr:objectMap [
      rr:column "title";
      rrx:languageColumn "title_lang";
      rr:language "en"  # default
   ]].

R2RML

my $result = $mapper->process($dbh);

is(
	$result->count_statements(
		iri('http://example.com/base/book/2'),
		iri('http://purl.org/dc/elements/1.1/title'),
		literal('Italian Food', 'en'),
	),
	1,
) or diag( $mapper->process_turtle($dbh) );

done_testing;
