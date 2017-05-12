# Pragmas.
use strict;
use warnings;

# Modules.
use Person::ID::CZ::RC;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Person::ID::CZ::RC::VERSION, 0.04, 'Version.');
