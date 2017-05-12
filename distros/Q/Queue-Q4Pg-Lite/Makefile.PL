use inc::Module::Install;
name 'Queue-Q4Pg-Lite';
all_from 'lib/Queue/Q4Pg/Lite.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';
requires 'Any::Moose';
requires 'SQL::Abstract';
requires 'DBI';
build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
