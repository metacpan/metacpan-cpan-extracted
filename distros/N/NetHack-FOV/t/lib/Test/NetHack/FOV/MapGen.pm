# vim: et sw=4

package Test::NetHack::FOV::MapGen;

use strict;
use warnings;

use constant LAYERS => 7;
use constant WIDTH  => 80;
use constant HEIGHT => 21;

srand(1);

sub layer {
    my ($map, $max, $tsize) = @_;

    my $tilesx = int((WIDTH  + $tsize - 1) / $tsize);
    my $tilesy = int((HEIGHT + $tsize - 1) / $tsize);

    my @smap;

    for my $y (0 .. $tilesy) {
        for my $x (0 .. $tilesx) {
            $smap[$y][$x] = rand() * $max;
        }
    }

    for my $y (0 .. HEIGHT-1) {
        my $ty = int ($y / $tsize);
        my $fy = ($y / $tsize) - $ty;

        for my $x (0 .. WIDTH-1) {
            my $tx = int ($x / $tsize);
            my $fx = ($x / $tsize) - $tx;

            $map->[$x][$y] += $smap[$ty  ][$tx  ] * (1 - $fy) * (1 - $fx)
                            + $smap[$ty  ][$tx+1] * (1 - $fy) * (    $fx)
                            + $smap[$ty+1][$tx  ] * (    $fy) * (1 - $fx)
                            + $smap[$ty+1][$tx+1] * (    $fy) * (    $fx);
        }
    }
}

sub gen_map {
    my ($density, $structure) = (rand, rand);

    $density = ($density + 1) / 3;
    $structure = exp(4 * $structure - 2);

    my @map;

    my $val = ($structure - 1) / ($structure ** LAYERS - 1);
    my $tsize = 1;

    for (0 .. LAYERS - 1) {
        layer \@map, $val, $tsize;
        $val *= $structure;
        $tsize *= 2;
    }

    for my $row (@map) {
        for (@$row) { $_ = ($_ < $density) ? 1 : 0; }
    }

    for my $y (0 .. HEIGHT-1) {
        $map[0][$y] = 1;
    }

    \@map;
}

1;
