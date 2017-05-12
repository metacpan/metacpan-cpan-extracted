#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild;
use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

my $mod = 'Test::BrewBuild';
my $sub = 'Test::BrewBuild::BrewCommands';

my $bb = $mod->new;
my $bc = $sub->new($bb->log);

if ($^O =~ /Win/){
    is ($bb->is_win, 1, "on windows, is_win() is ok");
    is ($bc->is_win, 1, "on windows, is_win() is ok (BrewCommands)");
}
else {
    is ($bb->is_win, 0, "on non windows, is_win() is ok");
    is ($bc->is_win, 0, "on non windows, is_win() is ok (BrewCommands)");
}
done_testing();

