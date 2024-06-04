use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Tags helper for message board.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.03;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Tags-HTML-Message-Board';
readme_from 'Board.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.06;
requires 'Data::HTML::Element::Button' => 0;
requires 'Data::HTML::Element::Textarea' => 0;
requires 'Error::Pure' => 0.07;
requires 'Mo::utils' => 0.06;
requires 'Mo::utils::CSS' => 0.02;
requires 'Mo::utils::Language' => 0.05;
requires 'Readonly' => 0;
requires 'Scalar::Util' => 0;
requires 'Tags::HTML' => 0.06;
requires 'Tags::HTML::Element::Button' => 0;
requires 'Tags::HTML::Element::Textarea' => 0;
requires 'perl' => '5.8.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Tags-HTML-Message-Board/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Tags-HTML-Message-Board';
resources 'repository' => 'git://github.com/michal-josef-spacek/Tags-HTML-Message-Board';
test_requires 'CSS::Struct::Output::Structure' => 0;
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Tags::Output::Structure' => 0;
test_requires 'Test::MockObject' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Shared::Fixture::Data::Message::Board::Example' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
