use inc::Module::Install;

name     'NetHack-Monster-Spoiler';
all_from 'lib/NetHack/Monster/Spoiler.pm';

requires       'YAML';
requires       'Moose';
requires       'MooseX::ClassAttribute';
requires       'MooseX::Role::Matcher';

build_requires 'Test::More';

WriteAll;

