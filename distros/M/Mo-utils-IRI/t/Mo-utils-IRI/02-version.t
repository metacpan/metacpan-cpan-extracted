use strict;
use warnings;

use Mo::utils::IRI;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Mo::utils::IRI::VERSION, 0.03, 'Version.');
