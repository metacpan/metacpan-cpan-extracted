#!/usr/bin/env perl

# tests from KjetilK

use strict;
use Test::More;

use Attean;
use Attean::RDF qw(iri);



my $parser     = Attean->get_parser( 'turtle' )->new(base=>'http://example.org/');
my $iter = $parser->parse_iter_from_bytes( '</foo> a </Bar> .' );

my $store = Attean->get_store('Memory')->new();
$store->add_iter($iter->as_quads(iri('http://graph.invalid/')));
my $model = Attean::QuadModel->new( store => $store );

use RDF::RDFa::Generator;


subtest 'Default generator, old bugfix' => sub {
  ok(my $document = RDF::RDFa::Generator->new->create_document($model), 'Assignment OK');
  isa_ok($document, 'XML::LibXML::Document');
  my $string = $document->toString;
  
  unlike($string, qr|xmlns:http://www.w3.org/1999/02/22-rdf-syntax-ns#="rdf"|, 'RDF namespace shouldnt be reversed');
  like($string, qr|xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"|, 'Correct RDF namespace declaration');
};

subtest 'Default generator, single given NS' => sub {
  my $string = tests({ 'ex' => 'http://example.org/ns'}, 'xmlns:ex="http://example.org/ns"');
};

subtest 'Head generator, single given NS' => sub {
  my $string = tests({ 'ex' => 'http://example.org/ns'}, 'xmlns:ex="http://example.org/ns"', 'HTML::Head');

};

subtest 'Head generator, list of known prefixes' => sub {
  my $string = tests(['bibo', 'dbo', 'doap'], 'xmlns:bibo="http://purl.org/ontology/bibo/"', 'HTML::Head');
  like($string, qr|xmlns:dbo="http://dbpedia.org/ontology/"|, 'Correct dbo namespace declaration');
  like($string, qr|xmlns:doap="http://usefulinc.com/ns/doap#"|, 'Correct doap namespace declaration');
};

subtest 'Head generator, list of known uris' => sub {
  my $string = tests(["http://dbpedia.org/ontology/", "http://usefulinc.com/ns/doap#", "http://purl.org/ontology/bibo/"], 'xmlns:bibo="http://purl.org/ontology/bibo/"', 'HTML::Head');
  like($string, qr|xmlns:dbo="http://dbpedia.org/ontology/"|, 'Correct dbo namespace declaration');
  like($string, qr|xmlns:doap="http://usefulinc.com/ns/doap#"|, 'Correct doap namespace declaration');
};

subtest 'Head generator, list of unknown uris' => sub {
  my $string = tests(["http://example.org/ontology/", "http://nothinguseful.com/ns/doad#"], 'xmlns:doad="http://nothinguseful.com/ns/doad#"', 'HTML::Head');
  like($string, qr|xmlns:ontology="http://example.org/ontology/"|, 'Correct dbo namespace declaration');
};

subtest 'Pretty generator, single given NS' => sub {
  my $string = tests({ 'ex' => 'http://example.org/ns'}, 'xmlns:ex="http://example.org/ns"', 'HTML::Pretty');

};

subtest 'Pretty generator, list of known prefixes' => sub {
  my $string = tests(['bibo', 'dbo', 'doap'], 'xmlns:bibo="http://purl.org/ontology/bibo/"', 'HTML::Pretty');
  like($string, qr|xmlns:dbo="http://dbpedia.org/ontology/"|, 'Correct dbo namespace declaration');
  like($string, qr|xmlns:doap="http://usefulinc.com/ns/doap#"|, 'Correct doap namespace declaration');
};

subtest 'Pretty generator, list of known uris' => sub {
  my $string = tests(["http://dbpedia.org/ontology/", "http://usefulinc.com/ns/doap#", "http://purl.org/ontology/bibo/"], 'xmlns:bibo="http://purl.org/ontology/bibo/"', 'HTML::Pretty');
  like($string, qr|xmlns:dbo="http://dbpedia.org/ontology/"|, 'Correct dbo namespace declaration');
  like($string, qr|xmlns:doap="http://usefulinc.com/ns/doap#"|, 'Correct doap namespace declaration');
};

subtest 'Pretty generator, list of unknown uris' => sub {
  my $string = tests(["http://example.org/ontology/", "http://nothinguseful.com/ns/doad#"], 'xmlns:doad="http://nothinguseful.com/ns/doad#"', 'HTML::Pretty');
  like($string, qr|xmlns:ontology="http://example.org/ontology/"|, 'Correct dbo namespace declaration');
};

subtest 'Hidden generator, single given NS' => sub {
  my $string = tests({ 'ex' => 'http://example.org/ns'}, 'xmlns:ex="http://example.org/ns"', 'HTML::Hidden');

};

subtest 'Hidden generator, list of known prefixes' => sub {
  my $string = tests(['bibo', 'dbo', 'doap'], 'xmlns:bibo="http://purl.org/ontology/bibo/"', 'HTML::Hidden');
  like($string, qr|xmlns:dbo="http://dbpedia.org/ontology/"|, 'Correct dbo namespace declaration');
  like($string, qr|xmlns:doap="http://usefulinc.com/ns/doap#"|, 'Correct doap namespace declaration');
};

subtest 'Hidden generator, list of known uris' => sub {
  my $string = tests(["http://dbpedia.org/ontology/", "http://usefulinc.com/ns/doap#", "http://purl.org/ontology/bibo/"], 'xmlns:bibo="http://purl.org/ontology/bibo/"', 'HTML::Hidden');
  like($string, qr|xmlns:dbo="http://dbpedia.org/ontology/"|, 'Correct dbo namespace declaration');
  like($string, qr|xmlns:doap="http://usefulinc.com/ns/doap#"|, 'Correct doap namespace declaration');
};

subtest 'Hidden generator, list of unknown uris' => sub {
  my $string = tests(["http://example.org/ontology/", "http://nothinguseful.com/ns/doad#"], 'xmlns:doad="http://nothinguseful.com/ns/doad#"', 'HTML::Hidden');
  like($string, qr|xmlns:ontology="http://example.org/ontology/"|, 'Correct dbo namespace declaration');
};



sub tests {
  my ($ns, $expect, $generator) = @_;
  my %opts = (namespaces => $ns);
  if ($generator) {
	 $opts{style} = $generator;
  } else {
	 $generator = 'default';
  }
  ok(my $document = RDF::RDFa::Generator->new(%opts)->create_document($model), "Assignment of $generator generator OK");
  isa_ok($document, 'XML::LibXML::Document');
  my $string = $document->toString;
  like($string, qr|$expect|, 'Correct example namespace declaration');
  return $string;
}

done_testing();
