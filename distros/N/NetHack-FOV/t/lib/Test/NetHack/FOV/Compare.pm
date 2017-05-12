# vim: et sw=4
package Test::NetHack::FOV::Compare;

use strict;
use warnings;

use Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(compare);

use constant WIDTH  => 80;
use constant HEIGHT => 21;

use Test::More;

sub compare {
    my ($map, $px, $py, $r1, $r2) = @_;

    for my $y (0 .. HEIGHT - 1) {
        for my $x (0 .. WIDTH - 1) {
            if ($r1->[$x][$y] xor $r2->[$x][$y]) {
                fail();
                display($map, $px, $py, $r1, $r2);
                return;
            }
        }
    }

    pass();
}

sub display {
    my ($map, $px, $py, $r1, $r2) = @_;
    for my $y (0 .. HEIGHT - 1) {
        my $line = "\e[1m";
        for my $x (0 .. WIDTH - 1) {
            my $color = ($r1->[$x][$y] ? 1 : 0) + ($r2->[$x][$y] ? 2 : 0);
            $color = 7 if $color == 3;

            my $c = ($x == $px && $y == $py) ? '@' :
                ($map->[$x][$y] ? '#' : '.');

            $line .= "\e[3${color}m${c}";
        }
        diag "$line\e[0m\n";
    }
}

1;
