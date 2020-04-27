use strict;
use warnings;

use Tags::Utils::Preserve;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::Utils::Preserve::VERSION, 0.08, 'Version.');
