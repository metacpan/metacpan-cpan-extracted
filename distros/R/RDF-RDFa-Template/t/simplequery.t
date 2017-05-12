
use strict;
use Test::More;
use Test::Exception;

use Test::XML;

use FindBin qw($Bin);
use File::Util;
my($f) = File::Util->new();

my $datadir = $Bin . '/data/localqueries/';

use_ok('RDF::RDFa::Template::SimpleQuery');

# Get and parse the XHTML
my ($rat) = $f->load_file($datadir . 'dbpedia-comment/input.xhtml');

is_well_formed_xml($rat, "Input RDFa Template document is well-formed");

my ($rdfa) = $f->load_file($datadir . 'dbpedia-comment/expected.xhtml');

is_well_formed_xml($rdfa, "Got the expected RDFa document");

{
dies_ok { 
  no warnings;
  my $query = RDF::RDFa::Template::SimpleQuery->new(rat => $rat, 
						    filename => $datadir . 'dbpedia-comment.input.ttl');
} 'Dies if no syntax given';

dies_ok { 
  no warnings;
  my $query = RDF::RDFa::Template::SimpleQuery->new(rat => $rat, syntax => 'rdfxml',
						    filename => $datadir . 'dbpedia-comment.input.ttl');
} 'Dies if wrong syntax given';


dies_ok { 
  no warnings;
  my $query = RDF::RDFa::Template::SimpleQuery->new(rat => $rat, 
						    filename => $datadir . 'foo.ttl');
} 'Dies if file doesnt exist';

  my $query = RDF::RDFa::Template::SimpleQuery->new(rat => $rat, 
						    filename => $datadir . 'dbpedia-comment/input.ttl',
						    syntax => 'turtle');
  isa_ok($query, 'RDF::RDFa::Template::SimpleQuery');
  ok($query->execute, "Query executed successfully");

  my $output = $query->rdfa_xhtml;
  isa_ok($output, 'XML::LibXML::Document');
  is_xml($output->toStringC14N, $rdfa, "The output is the expected RDFa");

  use XML::LibXML::XPathContext;
  my $xpc = XML::LibXML::XPathContext->new($output); 
  my $uri = $xpc->lookupNs('rdfs');
  is($xpc->lookupNs('rdfs'), 'http://www.w3.org/2000/01/rdf-schema#', "rdfs namespace is correct ");

}

my ($rdf) = $f->load_file($datadir . 'dbpedia-comment/input.ttl');

ok(defined($rdf), "Got RDF test data");

{
dies_ok { 
  no warnings;
  my $query = RDF::RDFa::Template::SimpleQuery->new(rat => $rat, rdf => $rdf);
} 'Dies if no syntax given';

dies_ok { 
  no warnings;
  my $query = RDF::RDFa::Template::SimpleQuery->new(rat => $rat, syntax => 'rdfxml',
						    rdf => $rdf);
} 'Dies if wrong syntax given';


  my $query = RDF::RDFa::Template::SimpleQuery->new(rat => $rat, rdf => $rdf, syntax => 'turtle');
  isa_ok($query, 'RDF::RDFa::Template::SimpleQuery');
  ok($query->execute, "Query executed successfully");

  my $output = $query->rdfa_xhtml;
  isa_ok($output, 'XML::LibXML::Document');
  is_xml($output->toStringC14N, $rdfa, "The output is the expected RDFa");
}


{
  my $rdfparser = RDF::Trine::Parser->new( 'turtle' );
  my $storage = RDF::Trine::Store::Memory->temporary_store;
  my $model = RDF::Trine::Model->new($storage);
  $rdfparser->parse_into_model ( "http://example.org/", $rdf, $model );


  my $query = RDF::RDFa::Template::SimpleQuery->new(rat => $rat, model => $model);
  isa_ok($query, 'RDF::RDFa::Template::SimpleQuery');
  ok($query->execute, "Query executed successfully");


  my $output = $query->rdfa_xhtml;
  isa_ok($output, 'XML::LibXML::Document');
  is_xml($output->toStringC14N, $rdfa, "The output is the expected RDFa");

  use XML::LibXML::XPathContext;
  my $xpc = XML::LibXML::XPathContext->new($output);
  my $uri = $xpc->lookupNs('rdfs');
  is($xpc->lookupNs('rdfs'), 'http://www.w3.org/2000/01/rdf-schema#', "rdfs namespace is correct ");
}


done_testing();
