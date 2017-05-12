use inc::Module::Install;

name     'Term-ANSIColor-Markup';
author   'Kentaro Kuribayashi, <kentarok@cpan.org>',
license  'MIT';
all_from 'lib/Term/ANSIColor/Markup.pm';

requires 'Class::Accessor::Lvalue::Fast';
requires 'HTML::Parser';

build_requires 'Test::More';
build_requires 'Test::Exception';
use_test_base;
author_tests   'xt';
auto_include_deps;
WriteAll;
