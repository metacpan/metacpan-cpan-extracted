use inc::Module::Install;

name     'MooseX-Role-Cmd';
all_from 'lib/MooseX/Role/Cmd.pm';

requires 'Moose' => 0.60;
requires 'IPC::Cmd' => 0.42;

build_requires 'Test::Exception';

auto_install;
WriteAll;
