use strict;
use warnings;

use Mo::utils::Array;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Mo::utils::Array::VERSION, 0.02, 'Version.');
