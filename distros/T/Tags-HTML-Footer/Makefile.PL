use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Tags helper for HTML footer.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Tags-HTML-Footer';
perl_version 5.008;
readme_from 'Footer.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0;
requires 'Error::Pure' => 0;
requires 'Mo::utils::Language' => 0.05;
requires 'Readonly' => 0;
requires 'Scalar::Util' => 0;
requires 'Tags::HTML' => 0.06;
requires 'Unicode::UTF8' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Tags-HTML-Footer/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Tags-HTML-Footer';
resources 'repository' => 'git://github.com/michal-josef-spacek/Tags-HTML-Footer';
test_requires 'CSS::Struct::Output::Structure' => 0;
test_requires 'Data::HTML::Footer' => 0;
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Tags::Output::Structure' => 0;
test_requires 'Test::MockObject' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
