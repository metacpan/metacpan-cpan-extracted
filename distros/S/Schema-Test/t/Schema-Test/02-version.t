use strict;
use warnings;

use Schema::Test;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Schema::Test::VERSION, 0.02, 'Version.');
