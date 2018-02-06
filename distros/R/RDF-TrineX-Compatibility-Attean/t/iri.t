#!/usr/bin/env perl

use strict;
use Test::More;

use_ok('RDF::TrineX::Compatibility::Attean');
use_ok('RDF::Trine::Node::Resource');

can_ok('RDF::Trine::Node::Resource', 'abs');

my $iri = RDF::Trine::Node::Resource->new('http://example.org/dahut');

is($iri->uri, 'http://example.org/dahut', 'IRI roundtripped OK');

done_testing;
