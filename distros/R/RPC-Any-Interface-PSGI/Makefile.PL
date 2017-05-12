use inc::Module::Install;

name           'RPC-Any-Interface-PSGI';
all_from       'lib/RPC/Any/Interface/PSGI.pm',

requires       'RPC::Any';
requires       'Plack';
requires       'Moose';
test_requires  'Test::More';

resources
    repository  => 'https://github.com/sherwind/RPC-Any-Interface-PSGI.git',
    bugtracker  => 'https://github.com/sherwind/RPC-Any-Interface-PSGI/issues';

WriteAll;
