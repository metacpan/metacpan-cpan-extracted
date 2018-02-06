#!/usr/bin/env perl

use strict;
use Test::More;

use_ok('RDF::TrineX::Compatibility::Attean');

use_ok('RDF::Trine::Node');

can_ok('RDF::Trine::Node', 'equals');
can_ok('RDF::Trine::Node', 'ntriples_string');


done_testing;
