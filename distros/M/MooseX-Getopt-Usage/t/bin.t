#!/usr/bin/perl

use FindBin qw($Bin);
use lib ("$Bin/lib");
use Bin::Test;
Test::Class->runtests;
