use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Class for random set generation';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Random-Set';
perl_version 5.008;
readme_from 'Set.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Random-Set/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Random-Set';
resources 'repository' => 'git://github.com/michal-josef-spacek/Random-Set';
test_requires 'English' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.08';

# Run.
WriteAll();
