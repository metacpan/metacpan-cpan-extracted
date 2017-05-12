#!/usr/bin/perl

use FindBin qw($Bin);
use lib ("$Bin/lib");
use Basic::Test;
Test::Class->runtests;
