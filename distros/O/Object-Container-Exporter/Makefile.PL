use inc::Module::Install;
name 'Object-Container-Exporter';
all_from 'lib/Object/Container/Exporter.pm';

requires 'Class::Singleton';
requires 'Class::Load';

test_requires 'Test::More' => '0.94';

tests 't/*.t t/*/*.t';
author_tests('xt');

auto_set_repository;

WriteAll;
