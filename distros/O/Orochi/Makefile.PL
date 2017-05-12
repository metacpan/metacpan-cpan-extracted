use strict;
use inc::Module::Install;

name('Orochi');

all_from 'lib/Orochi.pm';

requires 'namespace::clean';
requires 'Data::Visitor';
requires 'Moose' => '0.93_01';
requires 'Module::Pluggable';
requires 'Path::Router';
requires 'Sub::Exporter';
test_requires 'Test::More' => 0.88;
test_requires 'Test::MockObject';
test_requires 'UNIVERSAL::can'; # MockObject apparently didn't declare it
test_requires 'UNIVERSAL::isa'; # MockObject apparently didn't declare it

auto_set_repository;

WriteAll;
