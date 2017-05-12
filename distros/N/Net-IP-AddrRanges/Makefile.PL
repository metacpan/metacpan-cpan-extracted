use inc::Module::Install;
name 'Net-IP-AddrRanges';
all_from 'lib/Net/IP/AddrRanges.pm';
readme_from 'lib/Net/IP/AddrRanges.pm';
githubmeta;

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
