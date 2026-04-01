use strict;
use warnings;

use NKC::Transform::BIBFRAME2MARC::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($NKC::Transform::BIBFRAME2MARC::Utils::VERSION, 0.06, 'Version.');
