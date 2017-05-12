use inc::Module::Install;
name 'MouseX-Param';
all_from 'lib/MouseX/Param.pm';

requires 'Mouse' => '0.14';

tests 't/*.t';
test_requires 'Test::More';
test_requires 'ok';
test_requires 'Test::Deep';
author_tests 'xt';
use_test_base;

auto_include_deps;
WriteAll;
