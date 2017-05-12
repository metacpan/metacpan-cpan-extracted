use strict;
use warnings;

use Test::More tests => 1;
use SVG;

# test: style

my $svg  = SVG->new;
my $defs = $svg->defs();
my $rect = $svg->rect(
    x      => 10,
    y      => 10,
    width  => 10,
    height => 10,
    style  => { fill => 'red', stroke => 'green' }
);
my $out = $svg->xmlify;
like( $out, qr/stroke\s*:\s*green/, "inline css defs" );

