use strict;
use warnings;

use Schema::Test::0_1_0::Result::Person;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Schema::Test::0_1_0::Result::Person::VERSION, 0.02, 'Version.');
