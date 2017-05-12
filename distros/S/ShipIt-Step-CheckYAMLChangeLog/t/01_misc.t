#!/usr/bin/env perl

use warnings;
use strict;
use ShipIt::Step::CheckYAMLChangeLog;
use FindBin '$Bin';
use Test::More tests => 1;

ok(ShipIt::Step::CheckYAMLChangeLog->check_file_for_version(
    "$Bin/../Changes", '0.01'),
    "this distribution's Changes file contains version 0.01");
