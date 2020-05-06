use strict;
use warnings;

use PYX::Optimization;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($PYX::Optimization::VERSION, 0.01, 'Version.');
