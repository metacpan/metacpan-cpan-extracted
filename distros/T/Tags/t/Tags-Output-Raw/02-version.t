# Pragmas.
use strict;
use warnings;

# Modules.
use Tags::Output::Raw;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::Output::Raw::VERSION, 0.06, 'Version.');
