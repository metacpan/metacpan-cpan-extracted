#! /usr/bin/perl
# vim: et sw=4

use strict;
use warnings;

use lib 't/lib';

use constant TESTS => 50;

BEGIN {
    require Test::More;
    Test::More::diag("Compiling reference NetHack code, this may take a few moments...");
    eval {
        require Test::NetHack::FOV::Real;
    };

    if ($@) {
        Test::More->import(skip_all => "Inline::C failed to load $@");
        exit;
    } else{
        Test::More->import(tests => TESTS());
    }
}

use NetHack::FOV;
use Test::NetHack::FOV::MapGen;
use Test::NetHack::FOV::Compare;

use constant LAYERS => 7;
use constant WIDTH  => 80;
use constant HEIGHT => 21;

sub gen_test {
    my $playerx   = int (rand() * (WIDTH));
    my $playery   = int (rand() * (HEIGHT));

    my $map = Test::NetHack::FOV::MapGen::gen_map;

    my $cb = sub {
        my ($x, $y) = @_;
        $x >= 0 && $y >= 0 && $x < WIDTH && $y < HEIGHT && !$map->[$x][$y];
    };

    my $r1 = Test::NetHack::FOV::Real::calculate_fov $playerx, $playery, $cb;
    my $r2 = NetHack::FOV::calculate_fov($playerx, $playery, $cb);

    Test::NetHack::FOV::Compare::compare $map, $playerx, $playery, $r1, $r2;
}

for (1 .. TESTS()) { gen_test }
