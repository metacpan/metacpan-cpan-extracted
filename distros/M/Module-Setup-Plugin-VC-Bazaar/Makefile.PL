use inc::Module::Install;
name 'Module-Setup-Plugin-VC-Bazaar';
all_from 'lib/Module/Setup/Plugin/VC/Bazaar.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

requires 'Module::Setup';
test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
