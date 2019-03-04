#!/usr/bin/perl
# 002_platform.t - check for supported platform (initially Linux only)

use strict;
use warnings;
use Config;

use Test::More tests => 1;                      # last test to print

is($Config{osname}, "linux", "PiFlash only runs on Linux");

1;
