#!/usr/bin/env perl

use lib qw(.);
use inc::Module::Install;

name     'Sub-Lib';
license  'Nil';
all_from 'lib/Sub/Lib.pm';

test_requires 'Test::More';

auto_install;
WriteAll;
