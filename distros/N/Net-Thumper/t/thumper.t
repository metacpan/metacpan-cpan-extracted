#!/usr/bin/perl


use FindBin qw($Bin);

use lib "$Bin/lib/";

use Test::Class;

use Test::Net::Thumper;

Test::Class->runtests;
