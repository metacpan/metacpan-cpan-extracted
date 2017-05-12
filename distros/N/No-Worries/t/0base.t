#!perl

use strict;
use warnings;
use Test::More tests => 1;

use No::Worries qw($ProgramName);

ok(defined($ProgramName), "\$ProgramName");
