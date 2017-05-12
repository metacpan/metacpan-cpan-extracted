# Pragmas.
use strict;
use warnings;

# Modules.
use Tags::Output::LibXML;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::Output::LibXML::VERSION, 0.02, 'Version.');
