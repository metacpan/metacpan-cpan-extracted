#!perl
use inc::Module::Install;

name     'MooseX-AttributeInflate';
all_from 'lib/MooseX/AttributeInflate.pm';

build_requires 'Test::More';
build_requires 'Test::Exception';

requires 'Moose' => 0.72;

auto_install;

WriteAll;

