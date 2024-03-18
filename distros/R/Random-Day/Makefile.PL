use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Class for random day generation';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Random-Day';
perl_version 5.006002;
readme_from 'Day.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'DateTime' => 0;
requires 'DateTime::Event::Random' => 0;
requires 'DateTime::Event::Recurrence' => 0;
requires 'Error::Pure' => 0.15;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Random-Day/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Random-Day';
resources 'repository' => 'git://github.com/michal-josef-spacek/Random-Day';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.14';

# Run.
WriteAll();
