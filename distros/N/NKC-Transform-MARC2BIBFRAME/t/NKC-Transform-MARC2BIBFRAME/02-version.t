use strict;
use warnings;

use NKC::Transform::MARC2BIBFRAME;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($NKC::Transform::MARC2BIBFRAME::VERSION, 0.05, 'Version.');
