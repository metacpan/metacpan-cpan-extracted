use inc::Module::Install;
name 'Scope-Container-DBI';
all_from 'lib/Scope/Container/DBI.pm';

requires 'Scope::Container', 0.04;
requires 'Log::Minimal';
requires 'List::Util';
requires 'Data::Dumper';
requires 'DBI', 1.615;
requires 'Module::Load';
requires 'Try::Tiny', 0.11;

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'Test::SharedFork';
test_requires 'DBD::SQLite';
test_requires 'File::Temp';

auto_set_repository;
#auto_include;
WriteAll;
