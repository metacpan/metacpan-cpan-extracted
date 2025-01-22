use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Install the Map::Tube modules.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
license 'artistic_2';
name 'Task-Map-Tube';
readme_from 'Tube.pm';
recursive_author_tests('xt');
requires 'Map::Tube' => 3.92;
requires 'Map::Tube::API' => 0.08;
requires 'Map::Tube::CLI' => 0.80;
requires 'Map::Tube::Graph' => 0.06;
requires 'Map::Tube::GraphViz' => 0.07;
requires 'Map::Tube::Exception' => 3.24;
requires 'Map::Tube::Plugin::Formatter' => 0.17;
requires 'Map::Tube::Plugin::FuzzyFind' => 0.81.1;
requires 'Map::Tube::Plugin::Graph' => 0.45;
requires 'Map::Tube::Server' => 0.06;
requires 'Map::Tube::Text::Shortest' => 0.02;
requires 'Map::Tube::Text::Table' => 0.05;
requires 'Task::Map::Tube::Metro' => 0.13;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Task-Map-Tube/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Task-Map-Tube';
resources 'repository' => 'git://github.com/michal-josef-spacek/Task-Map-Tube';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.48';

# Run.
WriteAll();
