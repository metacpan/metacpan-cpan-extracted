use RDF::Query;
use RDF::TrineX::Functions -shortcuts;

my $data = rdf_parse(<<'TURTLE', type=>'turtle', base=>'http://example.com/');
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

<http://tobyinkster.co.uk/#i>
	foaf:name "Toby Inkster" ;
	foaf:phone "01234567890x1234";
	foaf:postcode "bn71rs" .
TURTLE

my $query = RDF::Query->new(<<'SPARQL');
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX sparql: <sparql:>
PREFIX gb: <http://buzzword.org.uk/2011/functions/gb#>
PREFIX util: <http://buzzword.org.uk/2011/functions/util#>
SELECT
	?name
	?phone
	?postcode
	(gb:postcode_format(?postcode) AS ?pcfmt)
	(gb:telephone_std(?phone) AS ?phonestd)
	(gb:telephone_local(?phone) AS ?phonelocal)
	(gb:telephone_extension(?phone) AS ?phoneext)
	(gb:telephone_uri(?phone) AS ?phoneuri)
WHERE
{
	?person foaf:name ?name ; foaf:phone ?phone ; foaf:postcode ?postcode .
}
SPARQL

print $query->execute($data)->as_xml;
