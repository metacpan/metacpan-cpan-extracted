#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild;
use Test::More;

my $mod = 'Test::BrewBuild';
my $bb = $mod->new;

my $cmd = $bb->is_win ? 'berrybrew.exe' : 'perlbrew';
my $sep = $bb->is_win ? ';' : ':';

if (! grep { -x "$_/$cmd"}split /$sep/,$ENV{PATH}){
    plan skip_all => "$cmd not installed... skipping";
}

my $info = $bb->brew_info;

plan skip_all => "no brew info found" if ! $info;

my @binfo = split /\n/, $info;

for (@binfo){
    next if /^$/;
    next if /(?:currently|following)/i;
    next if /\s+cperl/;
    like ($_, qr/\d\.\d{1,2}/, "$_ in brew_info contains a perl");
}

done_testing();

