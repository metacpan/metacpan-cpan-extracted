#!/usr/bin/env perl

use strict;
use Test::More;

use_ok('RDF::Trine::Serializer');
use_ok('RDF::Trine::Serializer::RDFa');

my $testmodel = RDF::Trine::Model->temporary_model;
my $parser = RDF::Trine::Parser->new( 'turtle' );

my $testdata = '<http://example.org/foo> a <http://example.org/Bar> ; <http://example.org/title> "Dahut"@fr ; <http://example.org/something> [ <http://example.org/else> "Foo" ; <http://example.org/pi> 3.14 ] .';

$parser->parse_into_model('http://example.org/', $testdata, $testmodel );

subtest 'Default generator' => sub {
  ok(my $s = RDF::Trine::Serializer->new('RDFa'), 'Assignment OK');
  isa_ok($s, 'RDF::Trine::Serializer');
  isa_ok($s, 'RDF::Trine::Serializer::RDFa');
  my $string = $s->serialize_model_to_string($testmodel);
  tests($string);
  like($string, qr|resource="http://example.org/Bar"|, 'Object present');
  like($string, qr|property="ex:title" content="Dahut"|, 'Literals OK');
};


subtest 'Hidden generator' => sub {
  ok(my $s = RDF::Trine::Serializer->new('RDFa', style => 'HTML::Hidden'), 'Assignment OK');
  isa_ok($s, 'RDF::Trine::Serializer::RDFa');
  my $string = $s->serialize_model_to_string($testmodel);
  tests($string);
  like($string, qr|resource="http://example.org/Bar"|, 'Object present');
  like($string, qr|property="ex:title" content="Dahut"|, 'Literals OK');
};

subtest 'Pretty generator' => sub {
  ok(my $s = RDF::Trine::Serializer->new('RDFa', style => 'HTML::Pretty'), 'Assignment OK');
  isa_ok($s, 'RDF::Trine::Serializer::RDFa');
  my $string = $s->serialize_model_to_string($testmodel);
  tests($string);
  like($string, qr|<dd property="ex:title" class="plain-literal" xml:lang="fr">Dahut</dd>|, 'Literals OK');
};

sub tests {
  my $string = shift;
  like($string, qr|about="http://example.org/foo"|, 'Subject URI present');
  like($string, qr|rel="rdf:type"|, 'Type predicate present');
  like($string, qr|property="ex:pi"|, 'pi predicate present');
  like($string, qr|3\.14|, 'pi decimal present');
}


done_testing;
