use inc::Module::Install;
name 'Parse-DaemontoolsStatus';
all_from 'lib/Parse/DaemontoolsStatus.pm';

#requires '';

test_requires 'Test::More' => '0.94';

tests 't/*.t t/*/*.t';
author_tests('xt');

auto_set_repository;

WriteAll;
