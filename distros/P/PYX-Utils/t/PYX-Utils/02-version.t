use strict;
use warnings;

use PYX::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($PYX::Utils::VERSION, 0.07, 'Version.');
