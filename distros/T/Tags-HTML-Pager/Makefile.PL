use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Tags helper for pager.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.03;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Tags-HTML-Pager';
readme_from 'Pager.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.02;
requires 'Error::Pure' => 0.07;
requires 'Exporter' => 0;
requires 'POSIX' => 0;
requires 'Readonly' => 0;
requires 'Tags::HTML' => 0;
requires 'Unicode::UTF8' => 0;
requires 'perl' => '5.8.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Tags-HTML-Pager/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Tags-HTML-Pager';
resources 'repository' => 'git://github.com/michal-josef-spacek/Tags-HTML-Pager';
test_requires 'CSS::Struct::Output::Structure' => 0;
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0.22;
test_requires 'File::Object' => 0.03;
test_requires 'Tags::Output::Raw' => 0;
test_requires 'Tags::Output::Structure' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Unicode::UTF8' => 0;
tests_recursive;
version '0.05';

# Run.
WriteAll();
