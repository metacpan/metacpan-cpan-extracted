use inc::Module::Install;
name 'Statistics-Associations';
all_from 'lib/Statistics/Associations.pm';
requires 'Carp';
build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
