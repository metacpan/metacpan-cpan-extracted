use strict;
use warnings;

use Random::Day::InTheFuture;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Random::Day::InTheFuture::VERSION, 0.17, 'Version.');
