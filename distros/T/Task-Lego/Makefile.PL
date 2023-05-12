use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Install the Lego modules.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Task-Lego';
readme_from 'Lego.pm';
recursive_author_tests('xt');
requires 'Lego::From::PNG' => 0.04;
requires 'Lego::Ldraw' => '0.5.8';
requires 'Lego::Part' => '0.03';
requires 'Lego::Part::Image' => '0.05';
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Task-Lego/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Task-Lego';
resources 'repository' => 'git://github.com/michal-josef-spacek/Task-Lego';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.04';

# Run.
WriteAll();
