#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

my @fits = (
    [cloak      => 'cloak of magic resistance'],
    [offhand    => 'cloak of magic resistance'],
    [cloak      => 'ornamental cope'],
    [weapon     => 'Cleaver'],
    [left_ring  => 'ring of regeneration'],
    [right_ring => 'sapphire ring'],
    [blindfold  => 'towel'],
);

my @doesnt_fit = (
    [helmet     => 'cloak of magic resistance'],
    [shield     => 'Cleaver'],
    [amulet     => 'sapphire ring'],
    [blindfold  => 'katana'],
);

fits_ok     @$_ for @fits;
fits_not_ok @$_ for @doesnt_fit;

done_testing;
