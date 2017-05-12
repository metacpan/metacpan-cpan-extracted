use inc::Module::Install;
name 'Net-MPRPC-Client';
all_from 'lib/Net/MPRPC/Client.pm';
readme_from 'lib/Net/MPRPC/Client.pm';

perl_version '5.008005';        # same to Data::MessagePack

requires 'Data::MessagePack' => '0.08';
requires 'Try::Tiny';

test_requires 'Test::More' => '0.88';
test_requires 'Test::TCP' => '1.12';

author_tests('xt');

auto_set_repository;

WriteAll;
