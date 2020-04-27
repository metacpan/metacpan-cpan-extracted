use strict;
use warnings;

use PYX::Format;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($PYX::Format::VERSION, 0.07, 'Version.');
