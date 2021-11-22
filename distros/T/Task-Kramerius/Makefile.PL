use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Install modules for Kramerius system.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Task-Kramerius';
perl_version 5.006;
readme_from 'Kramerius.pm';
recursive_author_tests('xt');
requires 'App::Kramerius::To::Images' => 0.03;
requires 'App::Kramerius::URI' => 0.03;
requires 'App::Kramerius::V4' => 0.02;
requires 'Data::Kramerius' => 0.04;
requires 'WebService::Kramerius::API4' => 0.01;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Task-Kramerius/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/Task-Kramerius';
resources 'repository' => 'git://github.com/michal-josef-spacek/Task-Kramerius';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
