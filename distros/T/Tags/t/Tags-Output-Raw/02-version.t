use strict;
use warnings;

use Tags::Output::Raw;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::Output::Raw::VERSION, 0.07, 'Version.');
