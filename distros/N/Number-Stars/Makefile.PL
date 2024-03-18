use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Class for conversion between percent number to star visualization';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Number-Stars';
perl_version 5.006002;
readme_from 'Stars.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'Error::Pure' => 0;
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Number-Stars';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Number-Stars';
resources 'repository' => 'git://github.com/michal-josef-spacek/Number-Stars';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
