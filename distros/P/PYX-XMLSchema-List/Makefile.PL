use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Processing PYX data or file and print list of XML schemas.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.07;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'PYX-XMLSchema-List';
readme_from 'List.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.05;
requires 'Error::Pure' => 0.16;
requires 'List::Util' => 0;
requires 'PYX::Parser' => 0.02;
requires 'Readonly' => 0;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/PYX-XMLSchema-List/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/PYX-XMLSchema-List';
resources 'repository' => 'git://github.com/michal-josef-spacek/PYX-XMLSchema-List';
test_requires 'English' => 0;
test_requires 'File::Object' => 0.07;
test_requires 'Error::Pure::Utils' => 0.22;
test_requires 'Perl6::Slurp' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 1.02;
tests_recursive;
version '0.06';

# Run.
WriteAll();
