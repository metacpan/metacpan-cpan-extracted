use strict;
use inc::Module::Install;

name('Script-Remote');
all_from('lib/Script/Remote.pm');

requires('Data::Dump');
requires('IPC::Open2');
requires('Moose');
requires('Path::Class');
requires('POSIX');

auto_include;
WriteAll;