#!/usr/bin/perl -w
#

use strict;
use Test::More tests => 2;

use PXP;

PXP::init();
ok(1);

PXP::init(configuration_file => './t/basic-conf.xml');
ok(1);

1;
