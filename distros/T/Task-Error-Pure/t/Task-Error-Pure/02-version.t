use strict;
use warnings;

use Task::Error::Pure;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Task::Error::Pure::VERSION, 0.04, 'Version.');
