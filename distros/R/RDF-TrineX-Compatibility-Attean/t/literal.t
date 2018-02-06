#!/usr/bin/env perl

use strict;
use Test::More;

use_ok('RDF::TrineX::Compatibility::Attean');

use_ok('RDF::Trine::Node::Literal');

can_ok('RDF::Trine::Node::Literal', 'value');
can_ok('RDF::Trine::Node::Literal', 'language');
can_ok('RDF::Trine::Node::Literal', 'datatype');

subtest 'plain literal string' => sub {
  my $lit = RDF::Trine::Node::Literal->new('Dahut');

  is($lit->value, 'Dahut', 'Value roundtripped');
  isa_ok($lit->datatype, 'RDF::Trine::Node::Resource');
  is($lit->datatype->value, 'http://www.w3.org/2001/XMLSchema#string', 'Datatype ok');
};

subtest 'language string literal' => sub {
  my $lit = RDF::Trine::Node::Literal->new('Dahut', 'fr');

  is($lit->value, 'Dahut', 'Value roundtripped');
  is($lit->language, 'fr', 'Language roundtripped');
  isa_ok($lit->datatype, 'RDF::Trine::Node::Resource');
  is($lit->datatype->value, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#langString', 'Datatype OK')
};

subtest 'datatype literal' => sub {
  my $lit = RDF::Trine::Node::Literal->new('42', undef, 'http://www.w3.org/2001/XMLSchema#integer');

  is($lit->value, '42', 'Value roundtripped');
  isa_ok($lit->datatype, 'RDF::Trine::Node::Resource');
  is($lit->datatype->value, 'http://www.w3.org/2001/XMLSchema#integer', 'datatype roundtripped');
};


done_testing;
