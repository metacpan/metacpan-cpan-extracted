use strict;
use warnings;

use Mo::utils::Language;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Mo::utils::Language::VERSION, 0.07, 'Version.');
