use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Mo utilities for IRI.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Mo-utils-IRI';
perl_version 5.006002;
readme_from 'IRI.pm';
recursive_author_tests('xt');
requires 'English' => 0;
requires 'Error::Pure' => 0.15;
requires 'Exporter' => 0;
requires 'Readonly' => 0;
requires 'IRI' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Mo-utils-IRI/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/Mo-utils-IRI';
resources 'repository' => 'git://github.com/michal-josef-spacek/Mo-utils-IRI';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Readonly' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Unicode::UTF8' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
