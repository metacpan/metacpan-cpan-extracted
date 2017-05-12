#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More tests => 1;

my $moduledir = "lib/Games/Sudoku/Trainer";
my $exampdir = "$moduledir/examples";
ok(-d $exampdir, "directory $exampdir exists") or BAIL_OUT('Dir examples not found');

