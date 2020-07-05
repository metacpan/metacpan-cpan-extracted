use strict;
use warnings;

use Test::More tests => 2;
use SVG;

my $svg = SVG->new();
my $g   = $svg->group( fill => "white", stroke => "black" );

my $fill = $g->attribute("fill");
is( $fill, "white", "attribute (get)" );

$g->attribute( stroke => "red" );
my $stroke = $g->attribute("stroke");
is( $stroke, "red", "attribute (set)" );

