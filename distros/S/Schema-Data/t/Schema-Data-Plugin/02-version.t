use strict;
use warnings;

use Schema::Data::Plugin;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Schema::Data::Plugin::VERSION, 0.05, 'Version.');
