use inc::Module::Install;

name 'Test-Deep-Matcher';
license 'perl';
all_from 'lib/Test/Deep/Matcher.pm';

requires 'parent';
requires 'Exporter';
requires 'Test::Deep';
requires 'Data::Util';

tests 't/*.t';
test_requires 'Test::More' => 0.98;
test_requires 'Test::UseAllModules';
test_requires 'Test::Tester';
test_requires 'Test::Deep';
test_requires 'Symbol';

author_tests 'xt';
auto_set_repository;

WriteAll;
