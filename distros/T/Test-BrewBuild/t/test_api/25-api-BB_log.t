#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild;
use Test::More;

my $mod = 'Test::BrewBuild';
my $bb = $mod->new;

my $brew_prog = $bb->is_win ? 'berrybrew.exe' : 'perlbrew';
my $sep = $bb->is_win ? ';' : ':';

if (! grep { -x "$_/$brew_prog"}split /$sep/,$ENV{PATH}){
    plan skip_all => "$brew_prog not installed... skipping";
}

is (ref $bb->log, 'Logging::Simple', "log() returns a proper obj");

done_testing();

