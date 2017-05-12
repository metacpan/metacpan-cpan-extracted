use inc::Module::Install;

name 'MooseX-Runnable-Fuse';
all_from 'lib/MooseX/Runnable/Fuse.pm';
repository 'http://github.com/jrockway/moosex-runnable-fuse';

requires 'MooseX::Declare';
requires 'MooseX::Getopt';
requires 'MooseX::Runnable';
requires 'MooseX::Types::Moose';
requires 'MooseX::Types::Path::Class';
requires 'Fuse';

build_requires 'Test::More';
build_requires 'ok';

WriteAll();
