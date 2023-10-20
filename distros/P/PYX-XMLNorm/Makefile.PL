use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Processing PYX data or file and do XML normalization.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.07;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'PYX-XMLNorm';
readme_from 'XMLNorm.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.05;
requires 'Error::Pure' => 0.15;
requires 'PYX' => 0.01;
requires 'PYX::Parser' => 0.03;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/PYX-XMLNorm/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/PYX-XMLNorm';
resources 'repository' => 'git://github.com/michal-josef-spacek/PYX-XMLNorm';
test_requires 'English' => 0;
test_requires 'File::Object' => 0.07;
test_requires 'File::Slurp' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 1.02;
tests_recursive;
version '0.05';

# Run.
WriteAll();
