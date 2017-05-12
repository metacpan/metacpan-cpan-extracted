use inc::Module::Install;

name            'Net-Sieve-Script';
perl_version    '5.006';
all_from        'lib/Net/Sieve/Script.pm';
version_from    'lib/Net/Sieve/Script.pm';

requires 'Class::Accessor::Fast' => 0.30;

build_requires  'Pod::Coverage';
build_requires  'Test::More';

auto_install;

tests('t/*.t');

WriteAll;

