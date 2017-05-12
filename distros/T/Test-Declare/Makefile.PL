use inc::Module::Install;
name 'Test-Declare';
all_from 'lib/Test/Declare.pm';

requires 'Exporter';
requires 'PPI';
requires 'Test::Deep';
requires 'Test::Exception';
requires 'Test::More';
requires 'Test::Warn';
requires 'Test::Output';
requires 'IO::Scalar';
requires 'Scalar::Util';

author_tests('xt');

use_test_base;
build_requires 'Test::More';
build_requires 'Test::Builder';
build_requires 'Test::Tester';
build_requires 'YAML'; # Test::Base require this

auto_include;
auto_set_repository;
WriteAll;
