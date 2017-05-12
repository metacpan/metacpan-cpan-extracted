#!/usr/bin/env perl

use inc::Module::Install;

use strict;
use warnings;

name           'Proc-Simple-Async';
all_from       'lib/Proc/Simple/Async.pm';

requires       'Proc::Simple' => '0';

build_requires 'Test::More' => '0.47';

auto_install;
WriteAll;

