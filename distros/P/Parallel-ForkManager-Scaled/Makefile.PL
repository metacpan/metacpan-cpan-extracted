#!/usr/bin/env perl

use lib '.';
use inc::Module::Install;

name     'Parallel-ForkManager-Scaled';
all_from 'lib/Parallel/ForkManager/Scaled.pm';
auto_set_repository;

requires 'List::Util';
requires 'Moo';
requires 'Parallel::ForkManager' => '2.00';
requires 'Unix::Statgrab';
requires 'namespace::clean';
requires 'Storable';

test_requires 'Test::More';

no_index directory => 'examples';
no_index directory => '.hg';

# install_script glob('script/*.pl');
auto_install;
WriteAll;
