#!/usr/bin/perl -w

use strict;
use Test::More tests => 1;

use Shell::Command;

pass();

exit 0;

fail("This test should never be run if Shell::Command is not interfering ".
     "with exit");
