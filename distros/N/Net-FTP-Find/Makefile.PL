use inc::Module::Install;
name 'Net-FTP-Find';
all_from 'lib/Net/FTP/Find.pm';

requires 'Net::FTP';
requires 'File::Listing';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More' => '0.88';
test_requires 'Test::TCP';
test_requires 'Test::FTP::Server';

auto_set_repository;
auto_include;
WriteAll;
