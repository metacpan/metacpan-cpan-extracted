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

my $info = $bb->brew_info;
my @installed = $bb->perls_installed($info);

if ($info && ($info =~ /(?:\s?\*?i\s|install)/)){
    ok (@installed, "if a perl is installed, it shows");
    for (@installed){
        like ($_, qr/\d\.\d{1,2}/, "each installed perl is a perl $_");
    }
}
else {
    is (@installed, 0, 'with no perls installed, empty array is returned');
}

done_testing();

