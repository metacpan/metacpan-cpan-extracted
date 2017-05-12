use strict;
use warnings;

use Test::More tests => 4;

use SVG;

# test: style

my $svg  = SVG->new;
my $defs = $svg->defs();

diag 'a five-sided polygon';
my $xv = [ 0, 2, 4, 5, 1 ];
my $yv = [ 0, 0, 2, 7, 5 ];

my $points = $svg->get_path(
    x     => $xv,
    y     => $yv,
    -type => 'polygon'
);

my $c = $svg->polygon(
    %$points,
    id    => 'pgon1',
    style => {
        fill   => 'red',
        stroke => 'green',
    },
    opacity => 0.6,
);

ok( $c, "polygon 1: define" );

my $out = $svg->xmlify();

like( $out, qr/polygon/, "polygon 2: serialize" );
like( $out, qr/style/,   "inline css style 1" );
like( $out, qr/opacity/, "inline css style 2" );

