use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Module for getting example from POD.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Pod-Example';
readme_from 'Example.pm';
recursive_author_tests('xt');
requires 'Error::Pure' => 0.08;
requires 'Exporter' => 0;
requires 'Module::Info' => 0;
requires 'Pod::Abstract' => 0;
requires 'Readonly' => 0;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Pod-Example';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Pod-Example';
resources 'repository' => 'git://github.com/michal-josef-spacek/Pod-Example';
test_requires 'English' => 0;
test_requires 'File::Object' => 0.05;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.09';

# Run.
WriteAll();
