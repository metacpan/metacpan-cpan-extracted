use Test::More;
use Test::Exception;
use FindBin qw($Bin);


use File::Util;
my($f) = File::Util->new();

my $datadir = $Bin . '/data/localqueries/';

# Get and parse the XHTML
my ($rat) = $f->load_file($datadir . 'dbpedia-comment/input.xhtml');

use_ok('RDF::RDFa::Template::Document');
use_ok('RDF::RDFa::Template::SimpleQuery');
use_ok('RDF::RDFa::Parser');
use_ok('RDF::Trine');
use_ok('RDF::Trine::Store');



ok(defined($rat), "Got data");


my $parser = RDF::RDFa::Parser->new($rat, 'http://example.org/dbpedia-comment/', 
				    {
				     use_rtnlx => 1,
				     graph => 1,
				     graph_type => 'about',
				     graph_attr => '{http://example.org/graph#}graph',
				    });

isa_ok($parser, 'RDF::RDFa::Parser');

ok($parser->consume, "Graph consumed");


my $doc = RDF::RDFa::Template::Document->new($parser);

isa_ok($doc, 'RDF::RDFa::Template::Document');

ok($doc->extract, "RDFa templates extracted");

{
  my $unit = $doc->unit('http://example.org/dbpedia-comment/query1');

  isa_ok($unit, 'RDF::RDFa::Template::Unit');

  isa_ok($unit->pattern, 'RDF::Query::Algebra::BasicGraphPattern');

  is($unit->pattern->as_sparql, "?resource <http://www.w3.org/2000/01/rdf-schema#comment> ?comment .\n?resource <http://www.w3.org/2000/01/rdf-schema#label> \"Resource Description Framework\"\@en .", "SPARQL BGP Matches") || diag $unit->pattern->as_sparql;
  dies_ok{$unit->results('foo')} 'Should croak on string';
  is_deeply($unit->results, {}, "Returns empty hashref");
  
}

foreach my $unit ($doc->units) {
  isa_ok($unit, 'RDF::RDFa::Template::Unit');
}




done_testing();
