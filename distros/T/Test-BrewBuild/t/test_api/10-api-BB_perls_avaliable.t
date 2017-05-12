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

my @perls_available = $bb->perls_available($bb->brew_info);

plan skip_all => "no brew info" if ! @perls_available;

ok (@perls_available, 'perls are available');

for (@perls_available){
    like ($_, qr/\d\.\d{1,2}/, "avail contains a perl: $_");
    unlike ($_, qr/cperl/, "avail doesn't contain cperl: $_");
}

done_testing();

