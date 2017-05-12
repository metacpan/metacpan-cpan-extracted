use inc::Module::Install;
name 'Template-Plugin-AddTime';
all_from 'lib/Template/Plugin/AddTime.pm';

requires 'Template::Plugin';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
