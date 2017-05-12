use inc::Module::Install;

name     'Plack-Middleware-AMF';
all_from 'lib/Plack/Middleware/AMF.pm';
author   q{Takuho Yoshizu <yoshizu@s2factory.co.jp>};
license  'perl';

build_requires 'Test::More';

requires 'Data::AMF' => '0.03';
requires 'Plack';
requires 'Plack::Request';
requires 'UNIVERSAL::require';

auto_install;

WriteAll;

