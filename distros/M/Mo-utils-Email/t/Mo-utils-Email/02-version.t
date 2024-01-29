use strict;
use warnings;

use Mo::utils::Email;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Mo::utils::Email::VERSION, 0.01, 'Version.');
