use inc::Module::Install;
name 'Net-POP3-SSLWrapper';
all_from 'lib/Net/POP3/SSLWrapper.pm';

requires 'Net::POP3'       => 2.29;
requires 'IO::Socket::SSL' => 1.34;
requires 'Net::Cmd'        => 2.29;
requires 'parent';

test_requires 'Test::More';
author_tests 'xt';
auto_include;
WriteAll;
