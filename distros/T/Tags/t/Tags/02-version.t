use strict;
use warnings;

use Tags;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::VERSION, 0.1, 'Version.');
