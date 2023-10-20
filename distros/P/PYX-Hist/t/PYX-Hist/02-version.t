use strict;
use warnings;

use PYX::Hist;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($PYX::Hist::VERSION, 0.08, 'Version.');
