use inc::Module::Install;
name 'Module-Install-Repository';
all_from 'lib/Module/Install/Repository.pm';
auto_set_repository;

test_requires 'Test::More';
test_requires 'Path::Class';

use_test_base;
auto_include_deps;
author_tests('xt');
WriteAll;
