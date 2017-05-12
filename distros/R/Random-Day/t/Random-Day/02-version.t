# Pragmas.
use strict;
use warnings;

# Modules.
use Random::Day;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Random::Day::VERSION, 0.05, 'Version.');
