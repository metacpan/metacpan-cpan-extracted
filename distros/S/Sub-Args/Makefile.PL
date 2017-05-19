use inc::Module::Install;
name 'Sub-Args';
all_from 'lib/Sub/Args.pm';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More' => '0.96';
auto_set_repository;
auto_include;
WriteAll;
