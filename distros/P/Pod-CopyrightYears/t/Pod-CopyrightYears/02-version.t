use strict;
use warnings;

use Pod::CopyrightYears;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Pod::CopyrightYears::VERSION, 0.01, 'Version.');
