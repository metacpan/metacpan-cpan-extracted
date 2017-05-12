use strict;
use warnings;
use 5.010;

use SVG;

# create an SVG object
my $svg= SVG->new( width => 200, height => 200);

my $tag = $svg->ellipse(
    cx => 10,
    cy => 10,
    rx => 5,
    ry => 7,
    id => 'ellipse',
    style => {
        'stroke'         => 'red',
        'fill'           => 'green',
        'stroke-width'   => '4',
        'stroke-opacity' => '0.5',
        'fill-opacity'   => '0.2',
    }
);
say $svg->xmlify;

