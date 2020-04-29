use strict;
use warnings;

use Tags::Output::LibXML;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::Output::LibXML::VERSION, 0.03, 'Version.');
