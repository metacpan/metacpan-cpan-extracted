#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild;
use Test::More;

my $mod = 'Test::BrewBuild';

{
    my $work_dir = $mod->workdir;
    is (-d $work_dir, 1, "workdir $work_dir created ok on install");
    is (-e "$work_dir/brewbuild.conf-dist", 1, "dist conf file created ok");
}

done_testing();

