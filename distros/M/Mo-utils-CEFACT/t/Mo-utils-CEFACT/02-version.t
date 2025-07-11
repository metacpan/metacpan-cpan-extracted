use strict;
use warnings;

use Mo::utils::CEFACT;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Mo::utils::CEFACT::VERSION, 0.03, 'Version.');
