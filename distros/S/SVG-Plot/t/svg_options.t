use strict;
local $^W = 1;
use SVG::Plot;
use Test::More tests => 1;

my $points = [ [0, 1, "abc"], [1, 2, "def"] ];
my $output = SVG::Plot->new(
                             points      => $points,
                             svg_options => {
                                              -nocredits => 1,
                                            },
                           )->plot;
unlike( $output, qr/Generated using the Perl SVG Module/i,
        "-nocredits options passed through to SVG.pm" );

