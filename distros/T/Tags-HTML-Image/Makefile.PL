use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Tags helper class for image presentation.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.03;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Tags-HTML-Image';
readme_from 'Image.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.02;
requires 'Error::Pure' => 0.07;
requires 'Mo::utils' => 0.12;
requires 'Mo::utils::CSS' => 0.02;
requires 'Scalar::Util' => 0;
requires 'Tags::HTML' => 0.06;
requires 'perl' => '5.8.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Tags-HTML-Image/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Tags-HTML-Image';
resources 'repository' => 'git://github.com/michal-josef-spacek/Tags-HTML-Image';
test_requires 'CSS::Struct::Output::Structure' => 0;
test_requires 'Data::Image' => 0;
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0.22;
test_requires 'File::Object' => 0.03;
test_requires 'Tags::Output::Structure' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.04';

# Run.
WriteAll();
