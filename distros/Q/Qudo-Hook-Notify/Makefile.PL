use inc::Module::Install;
name 'Qudo-Hook-Notify';
all_from 'lib/Qudo/Hook/Notify.pm';

requires 'Qudo::Plugin::Logger';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
