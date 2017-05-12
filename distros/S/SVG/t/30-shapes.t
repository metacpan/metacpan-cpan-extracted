use strict;
use warnings;

use Test::More tests => 3;

use SVG;

# test: style

subtest rectangle => sub {
    plan tests => 1;

    my $svg = SVG->new;
    my $tag = $svg->rectangle(
        x      => 10,
        y      => 20,
        width  => 4,
        height => 5,
        rx     => 5.2,
        ry     => 2.4,
        id     => 'rect_1',
    );
    my $xml = $svg->xmlify;
    like $xml,
        qr{<rect height="5" id="rect_1" rx="5.2" ry="2.4" width="4" x="10" y="20" />};

    #diag $xml;
};

subtest circle => sub {
    plan tests => 1;

    my $svg = SVG->new;
    my $tag = $svg->circle(
        cx => 100,
        cy => 100,
        r  => 50,
        id => 'circle_in_group_y'
    );
    my $xml = $svg->xmlify;
    like $xml, qr{<circle cx="100" cy="100" id="circle_in_group_y" r="50" />};

    #diag $xml;
};

subtest ellipse => sub {
    plan tests => 1;

    my $svg = SVG->new;
    my $tag = $svg->ellipse(
        cx    => 10,
        cy    => 10,
        rx    => 5,
        ry    => 7,
        id    => 'ellipse',
        style => {
            'stroke'         => 'red',
            'fill'           => 'green',
            'stroke-width'   => '4',
            'stroke-opacity' => '0.5',
            'fill-opacity'   => '0.2',
        }
    );
    my $xml = $svg->xmlify;
    like $xml,
        qr{<ellipse cx="10" cy="10" id="ellipse" rx="5" ry="7" style="fill: green; fill-opacity: 0.2; stroke: red; stroke-opacity: 0.5; stroke-width: 4" />};

    #diag $xml;
};

