use strict;
use warnings;

use Mo::utils::Text;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Mo::utils::Text::VERSION, 0.03, 'Version.');
