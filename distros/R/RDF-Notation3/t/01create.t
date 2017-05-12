use Test;
BEGIN { plan tests => 1 }
use RDF::Notation3::Triples;

my $rdf = new RDF::Notation3::Triples;

ok($rdf);

