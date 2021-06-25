#!perl
use strict;
use warnings;
use Test::Compile;

# all_pm_files_ok() calls 'plan()' and 'ok()' as required
# so we can't call those things in this script...
# this file is mostly just to increase the coverage.
all_pm_files_ok();
