use inc::Module::Install;
name 'MouseX-Types';
all_from 'lib/MouseX/Types.pm';

requires 'Mouse' => 0.77;
requires 'Any::Moose' => 0.15;

tests 't/*.t t/*/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'Scalar::Util';

auto_set_repository;
WriteAll;
