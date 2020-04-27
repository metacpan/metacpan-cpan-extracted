use strict;
use warnings;

use PYX;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($PYX::VERSION, 0.07, 'Version.');
