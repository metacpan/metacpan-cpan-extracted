use RDF::TrineX::Functions -shortcuts;
use RDF::Query;

my $data = rdf_parse(<<'TURTLE', type=>'turtle', base=>'http://example.com/');
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

<http://tobyinkster.co.uk/#i>
	foaf:birthday "1980-06-01"^^<http://www.w3.org/2001/XMLSchema#date> .
TURTLE

my $query = RDF::Query->new(<<'SPARQL');
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX util: <http://buzzword.org.uk/2011/functions/util#>
PREFIX dt:   <http://buzzword.org.uk/2011/functions/datetime#>
PREFIX xsd:  <http://www.w3.org/2001/XMLSchema#>
SELECT
	(dt:now() AS ?now)
	(dt:today() AS ?today)
	?bday
	(dt:format_duration(dt:difference(dt:now(), ?bday), "%Y years, %m months") AS ?age)
	(dt:add(?bday, "P10Y"^^xsd:duration) AS ?tenthbday)
	(dt:strtotime("yesterday morning"@en) AS ?yesterdaymorning)
	(dt:strftime(?bday, "%a, %d %b %Y"@en) AS ?fmtbday)
	(dt:strtodate("1/6/1980"@en-gb) AS ?guessbday)
WHERE
{
	?person foaf:birthday ?bday .
}
SPARQL

print $query->execute($data)->as_xml;