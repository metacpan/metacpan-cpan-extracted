use strict;
use warnings;

use Task::Curses::UI;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Task::Curses::UI::VERSION, 0.06, 'Version.');
