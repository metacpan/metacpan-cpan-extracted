use inc::Module::Install;
name 'Perlbal-Plugin-UrlGroup';
all_from 'lib/Perlbal/Plugin/UrlGroup.pm';

requires 'Perlbal';
requires 'URI::Escape';

author_tests('xt');

build_requires 'Test::More' => '0.94';
build_requires 'Test::TCP';

use_test_base;
auto_include;
auto_set_repository;
WriteAll;

