use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Processing PYX data or file and process element stack.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.07;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'PYX-Stack';
readme_from 'Stack.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.05;
requires 'Error::Pure' => 0.22;
requires 'PYX::Parser' => 0.02;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/PYX-Stack/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/PYX-Stack';
resources 'repository' => 'git://github.com/michal-josef-spacek/PYX-Stack';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0.22;
test_requires 'File::Object' => 0.07;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 1.02;
tests_recursive;
version '0.06';

# Run.
WriteAll();
