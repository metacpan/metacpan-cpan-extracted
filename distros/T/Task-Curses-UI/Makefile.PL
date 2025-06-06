use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Install the Curses::UI modules.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Task-Curses-UI';
readme_from 'UI.pm';
recursive_author_tests('xt');
requires 'Curses::UI' => 0.9609;
requires 'Curses::UI::AnyEvent' => 0.101;
requires 'Curses::UI::Char' => 0.02;
requires 'Curses::UI::DelimitedTextViewer' => 0.10;
requires 'Curses::UI::Grid' => 0.15;
requires 'Curses::UI::Mousehandler::GPM' => 0.01;
requires 'Curses::UI::Number' => 0.07;
requires 'Curses::UI::POE' => 0.04;
requires 'Curses::UI::Time' => 0.06;
requires 'Curses::UI::Volume' => 0.04;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Task-Curses-UI/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Task-Curses-UI';
resources 'repository' => 'git://github.com/michal-josef-spacek/Task-Curses-UI';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.06';

# Run.
WriteAll();
