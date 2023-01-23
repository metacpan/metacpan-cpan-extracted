use strict;
use warnings;

use String::UpdateYears;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($String::UpdateYears::VERSION, 0.01, 'Version.');
