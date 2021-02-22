use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'PYX optimization Perl class.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.07;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'PYX-Optimization';
readme_from 'Optimization.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.05;
requires 'Error::Pure' => 0.15;
requires 'PYX' => 0.01;
requires 'PYX::Parser' => 0.08;
requires 'PYX::Utils' => 0.01;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/PYX-Optimization/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/PYX-Optimization';
resources 'repository' => 'git://github.com/michal-josef-spacek/PYX-Optimization';
test_requires 'English' => 0;
test_requires 'File::Object' => 0.07;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Pod' => 0;
test_requires 'Test::Pod::Coverage' => 0;
test_requires 'Unicode::UTF8' => 0;
tests_recursive;
version '0.04';

# Run.
WriteAll();
