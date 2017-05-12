use inc::Module::Install;
name 'Number-Extreme';
all_from 'lib/Number/Extreme.pm';
readme_from 'lib/Number/Extreme.pm';
build_requires 'Test::More';
auto_include_deps;
author_tests('xt');
auto_set_repository;
WriteAll;
