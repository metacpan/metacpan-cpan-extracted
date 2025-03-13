use strict;
use warnings;

use Mo::utils::Unicode;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Mo::utils::Unicode::VERSION, 0.01, 'Version.');
