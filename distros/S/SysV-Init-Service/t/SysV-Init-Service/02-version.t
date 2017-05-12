# Pragmas.
use strict;
use warnings;

# Modules.
use SysV::Init::Service;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($SysV::Init::Service::VERSION, 0.06, 'Version.');
