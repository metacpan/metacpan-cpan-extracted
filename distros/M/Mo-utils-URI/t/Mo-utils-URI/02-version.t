use strict;
use warnings;

use Mo::utils::URI;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Mo::utils::URI::VERSION, 0.01, 'Version.');
