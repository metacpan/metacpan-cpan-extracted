use inc::Module::Install;
name 'Net-TinyIp';
all_from 'lib/Net/TinyIp.pm';
readme_from;

requires "Module::Install::ReadmeFromPod";
requires "Readonly";

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
