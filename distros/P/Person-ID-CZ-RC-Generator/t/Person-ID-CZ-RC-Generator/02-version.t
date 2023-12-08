use strict;
use warnings;

use Person::ID::CZ::RC::Generator;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Person::ID::CZ::RC::Generator::VERSION, 0.06, 'Version.');
