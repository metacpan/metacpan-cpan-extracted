use strict;
use warnings;

use PYX::GraphViz;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($PYX::GraphViz::VERSION, 0.06, 'Version.');
