use strict;
use warnings;
use inc::Module::Install;

name 'Params-Validate-Aggregated';

license 'gpl3';
all_from 'lib/Params/Validate/Aggregated.pm';

requires 'Params::Validate';
requires 'Data::Alias';
requires 'parent';

build_requires 'Test::More';
build_requires 'Storable';
build_requires 'Hash::Util';

auto_install;

WriteAll;
