#!perl
use strict;
use warnings;
use Test::More tests => 2;
use Test::Compile qw( all_files_ok );

# all_files_ok() calls 'ok()' as required
# so we can't that explicitly in this script...
# this file is mostly just to increase the coverage.
all_files_ok();
