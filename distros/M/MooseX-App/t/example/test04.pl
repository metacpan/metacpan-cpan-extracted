#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use FindBin qw();
use lib $FindBin::Bin.'/../testlib';

use Test04;
Test04->new_with_command->run;