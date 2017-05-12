use inc::Module::Install;
name 'SQL-Object';
all_from 'lib/SQL/Object.pm';

test_requires 'Test::More' => '0.94';

tests 't/*.t t/*/*.t';
author_tests('xt');

auto_set_repository;

WriteAll;
