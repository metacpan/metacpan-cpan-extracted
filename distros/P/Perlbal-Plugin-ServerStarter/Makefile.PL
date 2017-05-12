use inc::Module::Install;

name 'Perlbal-Plugin-ServerStarter';
all_from 'lib/Perlbal/Plugin/ServerStarter.pm';
readme_from 'lib/Perlbal/Plugin/ServerStarter.pm';
authority 'ZIGUZAGU';

install_script 'start_perlbal';

requires 'Perlbal';
requires 'Server::Starter';

test_requires 'Test::More', 0.96;
test_requires 'Test::TCP';
tests 't/*.t';
author_tests 'xt';

auto_include;
auto_set_repository;

WriteAll;
