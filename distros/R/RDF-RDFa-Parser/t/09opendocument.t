use Test::More;
use RDF::RDFa::Parser;

eval { require RDF::Query; require Archive::Zip; 'OK' }
	or plan skip_all => 'Need RDF::Query and Archive::Zip to run this test!';

plan tests => 1;

(my $file = __FILE__) =~ s/t$/odt/;
my $data  = do { local(@ARGV, $/) = $file; <> };
my $p     = RDF::RDFa::Parser->new(
	$data,
	'http://example.com/09opendocument.odt',
	RDF::RDFa::Parser::Config->new( RDF::RDFa::Parser::Config->HOST_OPENDOCUMENT_ZIP, '1.1', graph => 0 ),
);

my $query = RDF::Query->new(<<'SPARQL');
PREFIX dc: <http://purl.org/dc/elements/1.1/>
ASK WHERE {
	?u dc:example1 "B" .
	?u dc:example2 "EFG" .
	?u dc:example3 "FGH" .
	?u dc:example4 "GHI" .
	FILTER ( !isBlank(?u) )
}
SPARQL

my $result = $query->execute($p->graph);

ok($result->is_boolean and $result->get_boolean);
