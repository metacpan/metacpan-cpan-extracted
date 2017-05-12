# Pragmas.
use strict;
use warnings;

# Modules.
use PYX::Sort;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($PYX::Sort::VERSION, 0.03, 'Version.');
