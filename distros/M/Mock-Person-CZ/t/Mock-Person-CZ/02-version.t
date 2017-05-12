# Pragmas.
use strict;
use warnings;

# Modules.
use Mock::Person::CZ;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Mock::Person::CZ::VERSION, 0.04, 'Version.');
