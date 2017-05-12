# Pragmas.
use strict;
use warnings;

# Modules.
use Mock::Person::DE;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Mock::Person::DE::VERSION, 0.05, 'Version.');
