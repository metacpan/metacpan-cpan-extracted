#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Tapper::Test;

plan tests => 1;

is ( Tapper::Test::_suite_name(),      'Tapper-Test',                 "suite_name");
#like ( Tapper::Test::_suite_version(), qr/^\d+\.\d+/,                 "suite_version");
#like ( Tapper::Test::_ram(),           qr/^\d+.?B$/,                    "ram"); # too specific
#like ( Tapper::Test::_uname(),         qr/Linux.*\s+\.*\d+\.\d+\.\d+/, "uname");

