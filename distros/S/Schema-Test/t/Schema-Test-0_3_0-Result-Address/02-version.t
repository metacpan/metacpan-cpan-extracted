use strict;
use warnings;

use Schema::Test::0_3_0::Result::Address;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Schema::Test::0_3_0::Result::Address::VERSION, 0.02, 'Version.');
