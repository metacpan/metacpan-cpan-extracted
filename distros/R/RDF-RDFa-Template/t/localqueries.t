# The intention with this test is to loop directories with several
# files to check whether the input XML results in the expected output
# XHTML+RDFa, based on the data in a Turtle file.
# Currently, it doesn't loop, it just checks a four hard-coded files.

use Test::More;
use Test::XML;
use FindBin qw($Bin);

use_ok('RDF::RDFa::Template::Document');
use_ok('RDF::RDFa::Template::SAXFilter');
use RDF::Trine::Parser;
use RDF::RDFa::Parser;
use RDF::Trine::Store;
use RDF::Trine::Model;
use File::Util;
my($f) = File::Util->new();

my $datadir = $Bin . '/data/localqueries/';

my (@subdirs) = $f->list_dir($datadir,'--dirs-only');

foreach my $dir (@subdirs) {
  next if ($dir =~ m/^\./); # Skip .svn etc.

  # Get and parse the XHTML
  my ($rat) = $f->load_file($datadir .  $dir . '/input.xhtml');

  is_well_formed_xml($rat, "Input RDFa Template document in $dir is well-formed");

  my $parser = RDF::RDFa::Parser->new($rat, 'http://example.org/foo/', 
				      {
				       use_rtnlx => 1,
				       graph => 1,
				       graph_type => 'about',
				       graph_attr => '{http://example.org/graph#}graph',
				      });

  ok($parser->consume, "The actual parsing went OK");
  my $doc = RDF::RDFa::Template::Document->new($parser);
  ok($doc->extract, "Extract the RDF graphs from the RDFa Template");

  # Get and parse the RDF test data

  my ($rdf) = $f->load_file($datadir .  $dir . '/input.ttl');

  ok(defined($rdf), "Got RDF test data from $dir");

  my $rdfparser = RDF::Trine::Parser->new( 'turtle' );
  my $storage = RDF::Trine::Store::Memory->temporary_store;
  my $model = RDF::Trine::Model->new($storage);
  $rdfparser->parse_into_model ( "http://example.org/", $rdf, $model );

  # Get the SPARQL Query we expect to get from the RDFa Template document
  
  # TODO: From here on, these tests does not reflect how RDFa Templates
  # are intended to work:
  #In an RDFa Template document, there may be several SPARQL queries
  #encoded in different named graphs. This is reflected in the foreach
  #below.
  my $i = 0;
  foreach my $unit ($doc->units) {
    my ($sparql) = $f->load_file($datadir .  $dir . "/expected-$i.rq");
    ok($sparql, "Got expected query from $dir/expected-$i.rq");

    my $query = 'SELECT * WHERE { ' . $unit->pattern->as_sparql . ' }';

    is($query, $sparql, "Correct SPARQL Query generated");

    my $engine = RDF::Query->new($query);

    my $iterator = $engine->execute($model);
    isa_ok($iterator, 'RDF::Trine::Iterator');
    ok($iterator->is_bindings, 'The returned results are variable bindings');
    ok($unit->results($iterator), 'The results were added successfully to $doc');
    $i++;
  }

  # This stuff needs to be the actual XML generation
  use XML::LibXML::SAX::Parser;
  use XML::LibXML::SAX::Builder;
  
  my $builder = XML::LibXML::SAX::Builder->new();
  my $sax = RDF::RDFa::Template::SAXFilter->new(Handler => $builder, Doc => $doc);

  my $generator = XML::LibXML::SAX::Parser->new(Handler => $sax);
  $generator->generate($doc->dom);

  my $output = $builder->result;

  isa_ok($output, 'XML::LibXML::Document');

  my ($rdfa) = $f->load_file($datadir .  $dir . '/expected.xhtml');

  is_well_formed_xml($rdfa, "Got the expected RDFa document from $dir");

  is_xml($output->toStringC14N, $rdfa, "The output is the expected RDFa");

  use XML::LibXML::XPathContext;
  my $xpc = XML::LibXML::XPathContext->new($output);
  my $uri = $xpc->lookupNs('rdfs');
  is($xpc->lookupNs('rdfs'), 'http://www.w3.org/2000/01/rdf-schema#', "rdfs namespace is correct ");
}

done_testing();
