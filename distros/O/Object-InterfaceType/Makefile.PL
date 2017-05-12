use inc::Module::Install;
name 'Object-InterfaceType';
all_from 'lib/Object/InterfaceType.pm';
readme_from 'lib/Object/InterfaceType.pm';
readme_pod_from 'lib/Object/InterfaceType.pm';
githubmeta;

requires 'Scalar::Util';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
