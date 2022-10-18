use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Tags helper for form.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Tags-HTML-Form';
perl_version 5.008;
readme_from 'Form.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0;
requires 'Data::HTML::Button' => 0.04;
requires 'Data::HTML::Form' => 0.04;
requires 'Error::Pure' => 0;
requires 'Scalar::Util' => 0;
requires 'Tags::HTML' => 0.04;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Tags-HTML-Form/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Tags-HTML-Form';
resources 'repository' => 'git://github.com/michal-josef-spacek/Tags-HTML-Form';
test_requires 'CSS::Struct::Output::Structure' => 0;
test_requires 'Data::HTML::Button' => 0.04;
test_requires 'Data::HTML::Form' => 0.04;
test_requires 'Data::HTML::Form::Input' => 0.04;
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Tags::Output::Raw' => 0;
test_requires 'Tags::Output::Structure' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.04';

# Run.
WriteAll();
