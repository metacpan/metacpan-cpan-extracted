#!perl
#
# Copyright (c) 2018-2022, Steven Bakker.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl 5.14.0. For more details, see the full text
# of the licenses in the directory LICENSES.
#

use 5.014;
use warnings;

use Test::More 1.001002;
use Test::Compile v1.2.0;

my @pms = all_pm_files;
my @pls = all_pl_files;

if ( ($::ENV{SKIP_ALL} || $::ENV{SKIP_COMPILE}) && !$::ENV{RUN_COMPILE} ) {
    plan skip_all => 'skip compilation because of environment';
}
else {
    plan tests => int(@pms) + int(@pls);
}

pm_file_ok($_) for @pms;
pl_file_ok($_) for @pls;
