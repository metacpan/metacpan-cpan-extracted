use inc::Module::Install;
#use Module::Install::AuthorTests;
#use Module::Install::Repository;

name     'Net-SSL-ExpireDate';
perl_version '5.006';
all_from 'lib/Net/SSL/ExpireDate.pm';
license  'perl';
auto_set_repository;

requires 'Class::Accessor';
requires 'IO::Socket';
requires 'Crypt::OpenSSL::X509';
requires 'Date::Parse';
requires 'DateTime';
requires 'DateTime::Duration';
requires 'Time::Duration::Parse';
requires 'UNIVERSAL::require';

test_requires 'Test::More';

tests_recursive;
author_tests 'xt';

use_test_base;
WriteAll;
