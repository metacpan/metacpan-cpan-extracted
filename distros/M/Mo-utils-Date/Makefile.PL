use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Mo date utilities.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Mo-utils-Date';
perl_version 5.006002;
readme_from 'Date.pm';
recursive_author_tests('xt');
requires 'DateTime' => 0;
requires 'English' => 0;
requires 'Error::Pure' => 0.15;
requires 'Exporter' => 0;
requires 'Readonly' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Mo-utils-Date/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/Mo-utils-Date';
resources 'repository' => 'git://github.com/michal-josef-spacek/Mo-utils-Date';
test_requires 'DateTime' => 0;
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.03';

# Run.
WriteAll();
