# Pragmas.
use strict;
use warnings;

# Modules.
use Tags::Utils::Preserve;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Tags::Utils::Preserve::VERSION, 0.06, 'Version.');
