use strict;
use warnings;

use Mo::utils::UDC;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Mo::utils::UDC::VERSION, 0.01, 'Version.');
