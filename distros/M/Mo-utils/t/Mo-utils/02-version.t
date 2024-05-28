use strict;
use warnings;

use Mo::utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Mo::utils::VERSION, 0.29, 'Version.');
