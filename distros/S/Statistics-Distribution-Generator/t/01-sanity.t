#!perl -T

use strict;
use warnings;
use Test::More tests => 8;
use lib '.';

use Statistics::Descriptive;
use Statistics::Distribution::Generator qw( :all );

my $num_tests = $ENV{ SDG_TESTS } || 100_000;
my $accuracy = defined($ENV{ SDG_ACC }) ? $ENV{ SDG_ACC } : 0.01;

diag('Set $ENV{ SDG_TESTS } to control the number of iterations inside each sanity test (default 100K)') unless defined $ENV{ SDG_TESTS };
diag('Set $ENV{ SDG_ACC } to control the desired accuracy of each sanity test (default 0.01)') unless defined $ENV{ SDG_ACC };

{
    my $gaussian = gaussian(0, 1);
    my $s = Statistics::Descriptive::Sparse->new();
    for (1 .. $num_tests) {
        $s->add_data($gaussian);
    }
    ok(
        $s->standard_deviation > (1 - $accuracy)
        && $s->standard_deviation < (1 + $accuracy)
    );
    ok(
        $s->mean > -$accuracy
        && $s->mean < $accuracy
    );
}

{
    my $cointoss = supplied(0) | supplied(1);
    my $s = Statistics::Descriptive::Sparse->new();
    for (1 .. $num_tests) {
        $s->add_data($cointoss);
    }
    ok(
        $s->mean > (0.5 - $accuracy)
        && $s->mean < (0.5 + $accuracy)
    );
}

{
    my $coinA = supplied(0) | supplied(1);
    my $coinB = supplied(0) | supplied(1);
    my $twocoins = $coinA x $coinB;
    my $s = Statistics::Descriptive::Sparse->new();
    for (1 .. $num_tests) {
        $s->add_data($_) for @$twocoins;
    }
    ok(
        $s->mean > (0.5 - $accuracy)
        && $s->mean < (0.5 + $accuracy)
    );
}

{
    my $d3 = supplied(1) | supplied(2) | supplied(3);
    my $s = Statistics::Descriptive::Sparse->new();
    for (1 .. $num_tests) {
        $s->add_data($d3);
    }
    ok(
        $s->mean > (2 - $accuracy)
        && $s->mean < (2 + $accuracy)
    );
}

{
    my $heavy = supplied(0);
    my $light = supplied(1);
    $heavy->{ weight } = (1 / $accuracy) - 1;
    my $unfair_coin = $heavy | $light;
    my $s = Statistics::Descriptive::Sparse->new();
    for (1 .. $num_tests) {
        $s->add_data($unfair_coin);
    }
    ok(
        $s->mean <= (1 / $heavy->{ weight }) + $accuracy
    );
}

{
    # The robot from the POD
    my $forwards = gaussian(0, 0.5) x gaussian(3, 1) x gaussian(0, 0.5);
    my $backwards = gaussian(0, 0.5) x gaussian(-3, 1) x gaussian(0, 0.5);
    my $left = gaussian(-3, 1) x gaussian(0, 0.5) x gaussian(0, 0.5);
    my $right = gaussian(3, 1) x gaussian(0, 0.5) x gaussian(0, 0.5);
    my $up = gaussian(0, 0.5) x gaussian(0, 0.5) x gaussian(3, 1);
    my $down = gaussian(0, 0.5) x gaussian(0, 0.5) x gaussian(-3, 1);
    my $direction = $forwards | $backwards | $left | $right | $up | $down;
    my ($z, $y, $x) = @$direction;
    ok(
        (($z > -9 && $z < 9) && ($y > -1.25 && $y < 1.25) && ($x > -1.25 && $x < 1.25))
        ||
        (($z > -1.25 && $z < 1.25) && ($y > -9 && $y < 9) && ($x > -1.25 && $x < 1.25))
        ||
        (($z > -1.25 && $z < 1.25) && ($y > -1.25 && $y < 1.25) && ($x > -9 && $x < 9))
    );
}

{
    # The robot from the POD, inside out, kinda
    my $move = gaussian(-3, 1) | gaussian(3, 1);
    my $stationary = gaussian(0, 0.5);
    $stationary->{ weight } = 4;
    my $do_something = $move | $stationary;
    my $direction = $do_something x $do_something x $do_something;
    my ($z, $y, $x) = @$direction;
    ok(
        ($z > -9 && $z < 9) && ($y > -9 && $y < 9) && ($x > -9 && $x < 9)
    );
}
