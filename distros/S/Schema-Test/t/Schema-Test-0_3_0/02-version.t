use strict;
use warnings;

use Schema::Test::0_3_0;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Schema::Test::0_3_0::VERSION, 0.02, 'Version.');
