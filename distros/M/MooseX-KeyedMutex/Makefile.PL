use strict;
use inc::Module::Install;

name('MooseX-KeyedMutex');

all_from('lib/MooseX/KeyedMutex.pm');

requires('KeyedMutex', '0.05');
requires('Moose');

test_requires('Test::More');
test_requires('Test::Exception');
test_requires('Test::UseAllModules');

auto_include_deps;
WriteAll;