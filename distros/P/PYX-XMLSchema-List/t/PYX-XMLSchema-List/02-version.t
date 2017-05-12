# Pragmas.
use strict;
use warnings;

# Modules.
use PYX::XMLSchema::List;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($PYX::XMLSchema::List::VERSION, 0.04, 'Version.');
