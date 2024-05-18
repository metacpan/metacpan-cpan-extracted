use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Tags helper for gradient evaluation.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.03;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Tags-HTML-GradientIndicator';
perl_version 5.008;
readme_from 'GradientIndicator.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.02;
requires 'Error::Pure' => 0.07;
requires 'Mo::utils::CSS' => 0.07;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Tags-HTML-GradientIndicator/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Tags-HTML-GradientIndicator';
resources 'repository' => 'git://github.com/michal-josef-spacek/Tags-HTML-GradientIndicator';
test_requires 'CSS::Struct::Output::Raw' => 0;
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Tags::Output::Structure' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.05';

# Run.
WriteAll();
