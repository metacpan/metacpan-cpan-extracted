use inc::Module::Install;
name 'Module-Requires';
all_from 'lib/Module/Requires.pm';
readme_from 'lib/Module/Requires.pm';
readme_pod_from 'lib/Module/Requires.pm';
githubmeta;

requires 'Carp';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
