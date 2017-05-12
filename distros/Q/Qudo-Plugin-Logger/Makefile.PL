use inc::Module::Install;
name 'Qudo-Plugin-Logger';
all_from 'lib/Qudo/Plugin/Logger.pm';

requires 'Qudo';
requires 'Log::Dispatch::Configurator::Any';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
