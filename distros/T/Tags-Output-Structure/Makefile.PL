use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract "Structure class for 'Tags' output.";
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.01;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Tags-Output-Structure';
readme_from 'Structure.pm';
recursive_author_tests('xt');
requires 'Error::Pure' => 0.22;
requires 'Tags::Output' => 0.03;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Tags-Output-Structure/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Tags-Output-Structure';
resources 'repository' => 'git://github.com/michal-josef-spacek/Tags-Output-Structure';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.08';

# Run.
WriteAll();
