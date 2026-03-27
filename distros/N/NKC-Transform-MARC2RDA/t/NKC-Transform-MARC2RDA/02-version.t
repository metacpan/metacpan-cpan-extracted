use strict;
use warnings;

use NKC::Transform::MARC2RDA;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($NKC::Transform::MARC2RDA::VERSION, 0.02, 'Version.');
