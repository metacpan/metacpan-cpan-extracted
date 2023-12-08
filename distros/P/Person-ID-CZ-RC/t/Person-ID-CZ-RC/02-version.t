use strict;
use warnings;

use Person::ID::CZ::RC;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Person::ID::CZ::RC::VERSION, 0.05, 'Version.');
