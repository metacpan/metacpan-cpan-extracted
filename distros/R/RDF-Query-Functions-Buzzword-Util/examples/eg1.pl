use RDF::Query;
use RDF::TrineX::Functions -shortcuts;

my $data = rdf_parse(<<'TURTLE', type=>'turtle', base=>'http://example.com/');
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

<http://tobyinkster.co.uk/#i>
	foaf:name "Toby Inkster" ;
	foaf:page [ foaf:name "Toby Inkster" ] ;
	foaf:junk "Foo <ex xmlns=\"http://example.com/junk\">Bar</ex>"^^rdf:XMLLiteral ;
	foaf:mbox <mailto:tobyink@cpan.org> .
TURTLE

my $query = RDF::Query->new(<<'SPARQL');
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX util: <http://buzzword.org.uk/2011/functions/util#>
PREFIX junk: <http://example.com/junk> 
SELECT
	?name
	(util:uc(?name) AS ?ucname)
	(util:trim(util:sprintf("   Je m'apelle %s   "@fr, ?name)) AS ?intro)
	(util:skolem(?page, "oid") AS ?skolempage)
	(util:preg_replace("t", "x", ?name, "ig") AS ?mangled)
	(util:find_xpath("//junk:ex", ?junk, 0) AS ?found)
WHERE
{
	?person foaf:name ?name ; foaf:page ?page ; foaf:junk ?junk.
}
SPARQL

my $results = $query->execute($data);
print $results->as_xml;
