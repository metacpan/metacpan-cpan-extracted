use strict;
use warnings;

use NKC::Transform::BIBFRAME2MARC;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($NKC::Transform::BIBFRAME2MARC::VERSION, 0.07, 'Version.');
