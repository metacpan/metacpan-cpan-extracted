#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More tests => 10;
use Term::Drawille;

# draw different pixels
my @expected = ('⠁', '⠂', '⠄', '⡀', '⠈', '⠐', '⠠', '⢀');
for(my $i = 0; $i < 8; $i++) {
    my $canvas = Term::Drawille->new(
        width  => 2,
        height => 4,
    );

    use integer;
    $canvas->set($i / 4, $i % 4, 1);

    is $canvas->as_string, $expected[$i] . "\n";
}

# draw a line
my $size = 8;

my $canvas = Term::Drawille->new(
    width  => $size,
    height => $size,
);

for(my $i = 0; $i < $size; $i++) {
    $canvas->set($i, $i, 1);
}

my $string = $canvas->as_string;

is $string, "⠑⢄⠀⠀\n⠀⠀⠑⢄\n";

# what happens if I have a non-divisible width/length?

$size   = 10;
$canvas = Term::Drawille->new(
    width  => $size,
    height => $size,
);

for(my $i = 0; $i < $size; $i++) {
    $canvas->set($i, $i, 1);
}

$string = $canvas->as_string;

is $string, "⠑⢄⠀⠀⠀\n⠀⠀⠑⢄⠀\n⠀⠀⠀⠀⠑\n";
