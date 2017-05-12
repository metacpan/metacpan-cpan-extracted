use inc::Module::Install;
name 'Plack-App-Proxy-Selective';
readme_from 'lib/Plack/App/Proxy/Selective.pm';
all_from 'lib/Plack/App/Proxy/Selective.pm';

requires 'Plack::Component';
requires 'Plack::Util::Accessor';
requires 'Plack::App::Directory';
requires 'Plack::App::Proxy';
requires 'Path::Class';
requires 'Regexp::Common';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More' => '0.96';
test_requires 'Test::Most';
auto_set_repository;
auto_include;
WriteAll;
