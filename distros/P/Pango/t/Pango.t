#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;

use_ok ('Pango');

my @version = Pango->GET_VERSION_INFO;
is (@version, 3, 'version info is three items long');
ok (Pango->CHECK_VERSION(0, 0, 0), 'CHECK_VERSION pass');
ok (!Pango->CHECK_VERSION(50, 0, 0), 'CHECK_VERSION fail');
