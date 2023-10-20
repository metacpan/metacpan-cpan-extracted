use strict;
use warnings;

use PYX::XMLSchema::List;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($PYX::XMLSchema::List::VERSION, 0.06, 'Version.');
