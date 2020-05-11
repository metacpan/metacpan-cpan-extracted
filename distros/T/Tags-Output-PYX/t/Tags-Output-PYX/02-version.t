use strict;
use warnings;

use Tags::Output::PYX;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::Output::PYX::VERSION, 0.04, 'Version.');
