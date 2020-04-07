use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Generate random sets of Czech names.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Mock-Person-CZ';
readme_from 'CZ.pm';
recursive_author_tests('xt');
requires 'Exporter' => 0;
requires 'Readonly' => 0;
requires 'perl' => '5.8.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Mock-Person-CZ';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Mock-Person-CZ';
resources 'repository' => 'git://github.com/michal-josef-spacek/Mock-Person-CZ';
test_requires 'List::MoreUtils' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.05';

# Run.
WriteAll();
