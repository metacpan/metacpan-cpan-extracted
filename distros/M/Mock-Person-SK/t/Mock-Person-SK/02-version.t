use strict;
use warnings;

use Mock::Person::SK;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Mock::Person::SK::VERSION, 0.05, 'Version.');
