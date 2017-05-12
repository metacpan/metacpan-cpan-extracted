use inc::Module::Install;
name 'Squatting-On-PSGI';
all_from 'lib/Squatting/On/PSGI.pm';

requires 'Plack::Request';
requires 'Squatting' => '0.81';

build_requires 'Test::More';
use_test_base;
auto_include_deps;
author_tests('xt');
auto_set_repository;
WriteAll;
