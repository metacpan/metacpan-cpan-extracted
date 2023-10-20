use strict;
use warnings;

use PYX::XMLNorm;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($PYX::XMLNorm::VERSION, 0.05, 'Version.');
