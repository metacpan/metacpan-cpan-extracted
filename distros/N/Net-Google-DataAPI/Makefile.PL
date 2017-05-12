use inc::Module::Install;
name 'Net-Google-DataAPI';
all_from 'lib/Net/Google/DataAPI.pm';

requires 'Carp';
requires 'XML::LibXML';
requires 'XML::Atom';
requires 'Net::Google::AuthSub' => '0.5';
requires 'Digest::SHA1';
requires 'Net::OAuth';
requires 'Net::OAuth2' => '0.60';
requires 'LWP::UserAgent';
requires 'LWP::Protocol::https';
requires 'URI';
requires 'Lingua::EN::Inflect::Number';
requires 'Text::Glob';
requires_any_moose(
    prefer => 'Mouse',
    moose => '0.56',
    mouse => '0.51',
);

tests_recursive;
author_tests 'xt';

build_requires 'Test::More' => '0.88';
build_requires 'Test::Warn';
build_requires 'UNIVERSAL::isa';
build_requires 'UNIVERSAL::can';
build_requires 'Test::MockObject';
build_requires 'Test::MockModule';
build_requires 'Test::Exception';

auto_set_repository;
WriteAll;
