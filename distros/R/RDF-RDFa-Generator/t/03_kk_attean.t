#!/usr/bin/env perl

# tests from KjetilK

use strict;
use Test::More;
use Test::Modern;

BEGIN {
  use_ok('Attean') or BAIL_OUT "Attean required for tests";
  use_ok('RDF::RDFa::Generator');
}

use Attean::RDF qw(iri);

my $store = Attean->get_store('Memory')->new();
my $parser = Attean->get_parser('Turtle')->new(base=>'http://example.org/');

my $iter = $parser->parse_iter_from_bytes('<http://example.org/foo> a <http://example.org/Bar> ; <http://example.org/title> "Dahut"@fr ; <http://example.org/something> [ <http://example.org/else> "Foo" ; <http://example.org/pi> 3.14 ] .');

$store->add_iter($iter->as_quads(iri('http://graph.invalid/')));
my $model = Attean::QuadModel->new( store => $store );


subtest 'Default generator' => sub {
  ok(my $document = RDF::RDFa::Generator->new->create_document($model), 'Assignment OK');
  my $string = tests($document);
  like($string, qr|<link|, 'link element just local part');
  like($string, qr|resource="http://example.org/Bar"|, 'Object present');
  like($string, qr|property="ex:title" content="Dahut"|, 'Literals OK');
};


subtest 'Hidden generator' => sub {
  ok(my $document = RDF::RDFa::Generator::HTML::Hidden->new->create_document($model), 'Assignment OK');
  my $string = tests($document);
  like($string, qr|<body>\s?<i|, 'i element just local part');
  like($string, qr|resource="http://example.org/Bar"|, 'Object present');
  like($string, qr|property="ex:title" content="Dahut"|, 'Literals OK');
};

subtest 'Pretty generator' => sub {
  ok(my $document = RDF::RDFa::Generator::HTML::Pretty->new->create_document($model), 'Assignment OK');
  my $string = tests($document);
  like($string, qr|<dd property="ex:title" class="typed-literal" xml:lang="fr" datatype="rdf:langString">Dahut</dd>|, 'Language Literal OK');
  like($string, qr|<dd property="ex:else" class="typed-literal" datatype="xsd:string">Foo</dd>|, '"Plain" Literal OK');
};

subtest 'Pretty generator with interlink' => sub {
  ok(my $document = RDF::RDFa::Generator::HTML::Pretty->new()->create_document($model, interlink => 1, id_prefix => 'test'), 'Assignment OK');
  my $string = tests($document);
  like($string, qr|<main>\s?<div|, 'div element just local part');
  like($string, qr|<dd property="ex:title" class="typed-literal" xml:lang="fr" datatype="rdf:langString">Dahut</dd>|, 'Literals OK');
};

subtest 'Pretty generator with Note' => sub {
  ok(my $note = RDF::RDFa::Generator::HTML::Pretty::Note->new(iri('http://example.org/foo'), 'This is a Note'), 'Note creation OK');
  ok(my $document = RDF::RDFa::Generator::HTML::Pretty->new->create_document($model, notes => [$note]), 'Assignment OK');
  my $string = tests($document);
  like($string, qr|<aside>|, 'aside element found');
  like($string, qr|This is a Note|, 'Note text found');
};


sub tests {
  my $document = shift;
  isa_ok($document, 'XML::LibXML::Document');
  my $string = $document->toString;
  like($string, qr|about="http://example.org/foo"|, 'Subject URI present');
  like($string, qr|rel="rdf:type"|, 'Type predicate present');
  like($string, qr|property="ex:pi"|, 'pi predicate present');
  like($string, qr|3\.14|, 'pi decimal present');
  like($string, qr|datatype="xsd:decimal"|, 'pi decimal datatype present');
  return $string;
}
done_testing();
