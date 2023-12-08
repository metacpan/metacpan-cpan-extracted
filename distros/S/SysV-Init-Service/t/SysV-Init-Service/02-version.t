use strict;
use warnings;

use SysV::Init::Service;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($SysV::Init::Service::VERSION, 0.07, 'Version.');
