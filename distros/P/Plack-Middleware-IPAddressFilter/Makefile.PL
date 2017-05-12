use inc::Module::Install;
name 'Plack-Middleware-IPAddressFilter';
all_from 'lib/Plack/Middleware/IPAddressFilter.pm';
readme_from 'lib/Plack/Middleware/IPAddressFilter.pm';
githubmeta;

requires 'Plack';
requires 'Net::IP::AddrRanges';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
