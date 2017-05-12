use inc::Module::Install;
name 'Scope-Container';
all_from 'lib/Scope/Container.pm';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More', 0.88;
auto_set_repository;
auto_include;
WriteAll;
