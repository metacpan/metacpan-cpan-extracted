#!/usr/bin/env perl

use strict;
use Test::More;
use Test::RDF;
use RDF::Trine qw(iri);

use_ok('RDF::Trine::Serializer');
use_ok('RDF::Trine::Serializer::RDFa');

use Module::Load::Conditional qw[check_install];

my $rdfpr = check_install( module => 'RDF::Prefixes');

my $testmodel = RDF::Trine::Model->temporary_model;
my $parser = RDF::Trine::Parser->new( 'turtle' );

my $testdata = '<http://example.org/foo> a <http://example.org/Bar> ; <http://example.org/title> "Dahut"@fr ; <http://example.org/something> [ <http://example.org/else> "Foo" ; <http://example.org/pi> 3.14 ] .';

$parser->parse_into_model('http://example.org/', $testdata, $testmodel );

subtest 'Default generator' => sub {
  plan skip_all => 'RDF::Prefixes is not installed' unless $rdfpr;
  ok(my $s = RDF::Trine::Serializer->new('RDFa'), 'Assignment OK');
  isa_ok($s, 'RDF::Trine::Serializer');
  isa_ok($s, 'RDF::Trine::Serializer::RDFa');
  my $string = $s->serialize_model_to_string($testmodel);
  tests($string);
  like($string, qr|resource="http://example.org/Bar"|, 'Object present');
  like($string, qr|property="ex:title" content="Dahut"|, 'Literals OK');
};

my $ns = URI::NamespaceMap->new( { ex => iri('http://example.org/') });

subtest 'Hidden generator' => sub {
  ok(my $s = RDF::Trine::Serializer->new('RDFa', style => 'HTML::Hidden', namespacemap => $ns), 'Assignment OK');
  isa_ok($s, 'RDF::Trine::Serializer::RDFa');
  my $string = $s->serialize_model_to_string($testmodel);
  tests($string);
  like($string, qr|resource="http://example.org/Bar"|, 'Object present');
  like($string, qr|property="ex:title" content="Dahut"|, 'Literals OK');
};

subtest 'Pretty generator' => sub {
  ok(my $s = RDF::Trine::Serializer->new('RDFa', style => 'HTML::Pretty', namespacemap => $ns), 'Assignment OK');
  isa_ok($s, 'RDF::Trine::Serializer::RDFa');
  my $string = $s->serialize_model_to_string($testmodel);
  tests($string);
  like($string, qr|<dd property="ex:title" class="typed-literal" xml:lang="fr" datatype="rdf:langString">Dahut</dd>|, 'Language literals OK');
  like($string, qr|<dd property="ex:else" class="typed-literal" datatype="xsd:string">Foo</dd>|, '"Plain" Literal OK');
};

subtest 'Pretty generator with interlink' => sub {
  ok(my $s = RDF::Trine::Serializer->new('RDFa',
													  namespacemap => $ns,
													  style => 'HTML::Pretty',
													  generator_options => {interlink => 1, id_prefix => 'test'}),
	  'Assignment OK');
  my $string = $s->serialize_model_to_string($testmodel);
  tests($string);
  like($string, qr|<main>\s?<div|, 'div element just local part');
  like($string, qr|<dd property="ex:title" class="typed-literal" xml:lang="fr" datatype="rdf:langString">Dahut</dd>|, 'Literals OK');
};

subtest 'Pretty generator with Note' => sub {
  ok(my $note = RDF::RDFa::Generator::HTML::Pretty::Note->new(iri('http://example.org/foo'), 'This is a Note'), 'Note creation OK');
  ok(my $s = RDF::Trine::Serializer->new('RDFa',
													  style => 'HTML::Pretty',
													  namespacemap => $ns,
													  generator_options => {notes => [$note]}),
	  'Assignment OK');
  my $string = $s->serialize_model_to_string($testmodel);
  tests($string);
  like($string, qr|<aside>|, 'aside element found');
  like($string, qr|This is a Note|, 'Note text found');
};


sub tests {
  my $string = shift;
  is_valid_rdf($string, 'rdfa',  'RDFa is syntactically valid');
  like($string, qr|about="http://example.org/foo"|, 'Subject URI present');
  like($string, qr|rel="rdf:type"|, 'Type predicate present');
  like($string, qr|property="ex:pi"|, 'pi predicate present');
  like($string, qr|3\.14|, 'pi decimal present');
}


done_testing;
