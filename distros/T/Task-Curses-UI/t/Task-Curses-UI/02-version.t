# Pragmas.
use strict;
use warnings;

# Modules.
use Task::Curses::UI;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Task::Curses::UI::VERSION, 0.03, 'Version.');
