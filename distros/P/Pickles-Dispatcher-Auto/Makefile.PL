use strict;
use inc::Module::Install;

name 'Pickles-Dispatcher-Auto';
all_from 'lib/Pickles/Dispatcher/Auto.pm';
repository 'git://github.com/hirafoo/p5-Pickles-Dispatcher-Auto.git';

tests 't/*.t';
author_tests 'xt';

requires 'parent';
requires 'Class::Load';
requires 'Module::Pluggable::Object';
requires 'Pickles';
requires 'String::CamelCase';
test_requires 'Test::More' => '0.87';

default_test_target includes => "t/MyApp/lib";

auto_install;
auto_set_repository;
WriteAll;
