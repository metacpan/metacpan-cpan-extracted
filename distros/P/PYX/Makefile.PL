use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'A perl module for PYX handling.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.07;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'PYX';
readme_from 'PYX.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.05;
requires 'Encode' => 0;
requires 'Error::Pure' => 0.16;
requires 'Exporter' => 0;
requires 'PYX::Utils' => 0.02;
requires 'Readonly' => 0;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/PYX/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/PYX';
resources 'repository' => 'git://github.com/michal-josef-spacek/PYX';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0.16;
test_requires 'File::Object' => 0.07;
test_requires 'Perl6::Slurp' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 1.02;
tests_recursive;
version '0.10';

# Run.
WriteAll();
