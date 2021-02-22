use strict;
use warnings;

use PYX::Parser;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($PYX::Parser::VERSION, 0.08, 'Version.');
