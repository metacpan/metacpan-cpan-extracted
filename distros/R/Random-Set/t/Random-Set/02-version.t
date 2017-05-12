# Pragmas.
use strict;
use warnings;

# Modules.
use Random::Set;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Random::Set::VERSION, 0.04, 'Version.');
