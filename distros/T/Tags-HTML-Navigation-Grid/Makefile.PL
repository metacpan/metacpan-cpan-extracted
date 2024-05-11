use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Tags helper for navigation grid.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.03;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Tags-HTML-Navigation-Grid';
readme_from 'Grid.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0;
requires 'Error::Pure' => 0;
requires 'Tags::HTML' => 0.08;
requires 'Scalar::Util' => 0;
requires 'perl' => '5.8.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Tags-HTML-Navigation-Grid/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Tags-HTML-Navigation-Grid';
resources 'repository' => 'git://github.com/michal-josef-spacek/Tags-HTML-Navigation-Grid';
test_requires 'CSS::Struct::Output::Structure' => 0;
test_requires 'Data::Navigation::Item' => 0;
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Tags::Output::Structure' => 0;
test_requires 'Test::MockObject' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
