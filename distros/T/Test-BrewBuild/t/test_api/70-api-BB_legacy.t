#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild;
use Test::More;

my $mod = 'Test::BrewBuild';

{
    my $bb = $mod->new;

    is ($bb->legacy, 0, "legacy() default is disabled");
    is ($bb->legacy(1), 1, "legacy() can be enabled");
    is ($bb->legacy(0), 0, "... and disabled again");
}

done_testing();

