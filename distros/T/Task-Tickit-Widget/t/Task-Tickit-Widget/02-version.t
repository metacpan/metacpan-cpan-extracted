# Pragmas.
use strict;
use warnings;

# Modules.
use Task::Tickit::Widget;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Task::Tickit::Widget::VERSION, 0.05, 'Version.');
