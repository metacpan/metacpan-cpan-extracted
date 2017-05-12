# Pragmas.
use strict;
use warnings;

# Modules.
use Tags::Output;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::Output::VERSION, 0.06, 'Version.');
