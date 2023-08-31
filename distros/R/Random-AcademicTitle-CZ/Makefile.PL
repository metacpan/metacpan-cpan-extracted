use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Class for random Czech academic title.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Random-AcademicTitle-CZ';
perl_version 5.006002;
readme_from 'CZ.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'Readonly' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Random-AcademicTitle-CZ/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Random-AcademicTitle-CZ';
resources 'repository' => 'git://github.com/michal-josef-spacek/Random-AcademicTitle-CZ';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
