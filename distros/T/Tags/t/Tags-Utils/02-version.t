use strict;
use warnings;

use Tags::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::Utils::VERSION, 0.08, 'Version.');
