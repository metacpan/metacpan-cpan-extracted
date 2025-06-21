use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Mo hash utilities.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Mo-utils-Hash';
perl_version 5.006002;
readme_from 'Hash.pm';
recursive_author_tests('xt');
requires 'Error::Pure' => 0.15;
requires 'Exporter' => 0;
requires 'Readonly' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Mo-utils-Hash/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/Mo-utils-Hash';
resources 'repository' => 'git://github.com/michal-josef-spacek/Mo-utils-Hash';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
