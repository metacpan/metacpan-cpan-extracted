use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Tags helper for login button.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Tags-HTML-Login-Button';
perl_version 5.008;
readme_from 'Button.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0;
requires 'Error::Pure' => 0;
requires 'Tags::HTML' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Tags-HTML-Login-Button/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Tags-HTML-Login-Button';
resources 'repository' => 'git://github.com/michal-josef-spacek/Tags-HTML-Login-Button';
test_requires 'CSS::Struct::Output::Raw' => 0;
test_requires 'CSS::Struct::Output::Structure' => 0;
test_requires 'Tags::Output::Raw' => 0;
test_requires 'Tags::Output::Structure' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
