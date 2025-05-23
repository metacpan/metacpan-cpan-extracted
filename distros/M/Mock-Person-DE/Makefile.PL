use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Generate random sets of German names.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Mock-Person-DE';
readme_from 'DE.pm';
recursive_author_tests('xt');
requires 'Exporter' => 0;
requires 'List::MoreUtils' => 0;
requires 'Readonly' => 0;
requires 'perl' => '5.8.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Mock-Person-DE/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Mock-Person-DE';
resources 'repository' => 'git://github.com/michal-josef-spacek/Mock-Person-DE';
test_requires 'List::MoreUtils' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.06';

# Run.
WriteAll();
