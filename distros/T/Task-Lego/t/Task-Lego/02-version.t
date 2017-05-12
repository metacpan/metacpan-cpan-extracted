# Pragmas.
use strict;
use warnings;

# Modules.
use Task::Lego;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Task::Lego::VERSION, 0.03, 'Version.');
