use inc::Module::Install;
name 'Test-Attribute-AutoLevel';
all_from 'lib/Test/Attribute/AutoLevel.pm';

test_requires 'Test::More' => '0.94';
test_requires 'Capture::Tiny';

tests 't/*.t t/*/*.t';
author_tests('xt');

auto_set_repository;

WriteAll;
