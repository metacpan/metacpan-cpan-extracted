use inc::Module::Install;
use Module::Install::AuthorTests;
use Module::Install::Repository;

name 'Net-DBus-Skype-API';
all_from 'lib/Net/DBus/Skype/API.pm';

requires 'parent';
requires 'Net::DBus'      => '1.0.0';

test_requires 'Test::More' => 0.98;

tests 't/*.t';
author_tests 'xt';

auto_set_repository;

WriteAll;
