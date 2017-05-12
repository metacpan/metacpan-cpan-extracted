use inc::Module::Install;

name 'Nothing-Tiny';
all_from 'lib/Nothing/Tiny.pm';

build_requires 'Test::More';
build_requires 'ok';

WriteAll();
