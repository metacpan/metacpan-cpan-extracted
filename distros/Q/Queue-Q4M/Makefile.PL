use strict;
use inc::Module::Install;

name('Queue-Q4M');
all_from('lib/Queue/Q4M.pm');

requires('Any::Moose' => '0.04');

requires('DBI');
requires('Scope::Guard');
requires('SQL::Abstract');

no_index(directory => 'misc');

auto_include;
WriteAll;