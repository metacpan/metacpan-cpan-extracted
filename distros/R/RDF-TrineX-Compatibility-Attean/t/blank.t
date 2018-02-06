#!/usr/bin/env perl

use strict;
use Test::More;

use_ok('RDF::TrineX::Compatibility::Attean');
use_ok('RDF::Trine::Node::Blank');

can_ok('RDF::Trine::Node::Blank', 'value');

my $blank = RDF::Trine::Node::Blank->new('dahut');

is($blank->value, 'dahut', 'Blank roundtripped OK');

done_testing;
