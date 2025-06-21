use strict;
use warnings;

use Mo::utils::Hash;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Mo::utils::Hash::VERSION, 0.01, 'Version.');
