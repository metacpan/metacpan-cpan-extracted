use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract "Element utilities for 'Tags'.";
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Tags-Element';
readme_from 'Element.pm';
recursive_author_tests('xt');
requires 'Exporter' => 0;
requires 'Readonly' => 0;
requires 'perl' => '5.8.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Tags-Element/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Tags-Element';
resources 'repository' => 'git://github.com/michal-josef-spacek/Tags-Element';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.04';

# Run.
WriteAll();
