use inc::Module::Install;
name 'Net-Google-Spreadsheets';
all_from 'lib/Net/Google/Spreadsheets.pm';

requires 'Carp';
requires 'XML::Atom';
requires 'Net::Google::AuthSub';
requires 'Net::Google::DataAPI' => '0.27';
requires 'URI';
requires_any_moose(
    prefer => 'Mouse',
    moose => '0.56',
    mouse => '0.51',
);

tests_recursive;
author_tests 'xt';

build_requires 'Test::More' => '0.88';
build_requires 'Test::Exception';
build_requires 'Test::MockModule';
build_requires 'Test::MockObject';
auto_set_repository;
WriteAll;
