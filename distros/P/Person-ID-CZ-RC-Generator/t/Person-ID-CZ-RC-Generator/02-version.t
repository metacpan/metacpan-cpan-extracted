# Pragmas.
use strict;
use warnings;

# Modules.
use Person::ID::CZ::RC::Generator;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Person::ID::CZ::RC::Generator::VERSION, 0.05, 'Version.');
