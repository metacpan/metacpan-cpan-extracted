use strict;
use warnings;

use Mo::utils::Currency;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Mo::utils::Currency::VERSION, 0.01, 'Version.');
