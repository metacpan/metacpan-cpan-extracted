use inc::Module::Install;
name 'Template-Plugin-Lingua-JA-Regular-Unicode';
all_from 'lib/Template/Plugin/Lingua/JA/Regular/Unicode.pm';

requires 'Template';
requires 'Lingua::JA::Regular::Unicode';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
