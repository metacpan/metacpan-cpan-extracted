use inc::Module::Install;

name     'MooseX-AttributeDefaults';
version  '0.02';
author   'frodwith@cpan.org';
all_from 'lib/MooseX/AttributeDefaults.pm';

requires 'Moose';
build_requires 'Test::More';

auto_install;

WriteAll;
