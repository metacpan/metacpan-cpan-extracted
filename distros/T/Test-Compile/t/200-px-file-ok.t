#!perl
use strict;
use warnings;
use Test::More tests => 2;
use Test::Compile qw( pl_file_ok pm_file_ok );

# pl_file_ok() and pm_file_ok() both call 'ok()' as required
# so we can't that explicitly in this script...
# this file is mostly just to increase the coverage.
pl_file_ok('t/scripts/subdir/success.pl', 'success.pl compiles');
pm_file_ok('t/scripts/Module.pm', 'Module.pm compiles');
