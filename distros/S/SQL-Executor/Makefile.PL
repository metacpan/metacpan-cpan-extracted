use inc::Module::Install;
name 'SQL-Executor';
license  'perl';
all_from 'lib/SQL/Executor.pm';
readme_from 'lib/SQL/Executor.pm';
readme_markdown_from 'lib/SQL/Executor.pm';
readme_pod_from 'lib/SQL/Executor.pm';
githubmeta;

requires 'parent';
requires 'DBI' => 1.608;
requires 'Class::Accessor::Lite';
requires 'SQL::Maker';
requires 'Try::Tiny';
requires 'DBIx::Handler';
test_requires 'DBD::SQLite' => 1.27;

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
auto_set_repository;

WriteAll;
