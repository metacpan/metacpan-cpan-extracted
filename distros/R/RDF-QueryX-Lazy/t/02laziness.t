use Test::More tests => 2;
use RDF::QueryX::Lazy;

my $query = RDF::QueryX::Lazy->new(<<SPARQL, {lazy => {ex=>'http://example.com/'}});
SELECT *
WHERE {
	?person foaf:name ?name .
	OPTIONAL { ?person ex:homepage ?page . }
}
SPARQL

ok($query, 'Yeah, probably works');
is($query->as_sparql."\n", <<SPARQL, 'Yeah, works');
PREFIX ex: <http://example.com/>
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
SELECT * WHERE {
	?person foaf:name ?name .
	OPTIONAL {
		?person ex:homepage ?page .
	}
}
SPARQL
