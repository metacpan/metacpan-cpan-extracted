# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Processing PYX data or file and do XML normalization.';
author 'Michal Spacek <skim@cpan.org>';
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
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=PYX-XMLNorm';
resources 'homepage' => 'https://github.com/tupinek/PYX-XMLNorm';
resources 'repository' => 'git://github.com/tupinek/PYX-XMLNorm';
test_requires 'English' => 0;
test_requires 'File::Object' => 0.07;
test_requires 'File::Slurp' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 1.02;
tests_recursive;
version '0.04';

# Run.
WriteAll();
