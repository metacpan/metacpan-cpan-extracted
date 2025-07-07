use strict;
use warnings;

use Mo::utils::CSS;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Mo::utils::CSS::VERSION, 0.12, 'Version.');
