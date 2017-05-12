#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

use Test::More tests => 3;

use MyTestingModule;

ok(!eval {
  MyTestingModule->bar;
1; }, "Throws error when trying to call subroutine");

is(MyTestingModule->foo, "ok", "still can be used from bound");

ok(!eval {
  MyTestingModule->cleaned;
1; }, "Throws error when trying to call cleaned");


1;