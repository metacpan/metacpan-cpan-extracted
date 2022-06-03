#!perl
use strict;
use warnings;
use Test::More tests => 2;

use Test::Compile;

# this file is mostly just to increase the coverage.
# ..The main test should be testing Test::Compile->all_pl_files() directly

# Given
my $plinput = 't/scripts/subdir/success.pl';

# When
my @plfiles = all_pl_files($plinput);

# Then
is(@plfiles, 1, 'got one specified PL file'); 
is($plfiles[0], $plinput, 'got the specified PL file'); 
