#!/usr/bin/perl

use v5.26;

use PDF::API2;
use SVGPDF;

# Setup the PDF.
my $pdf = PDF::API2->new;

# Setup the SVG engine and process SVG data.
my $svg = SVGPDF->new( $pdf, verbose => 0 );
my $xof = $svg->process(\*DATA);

# If all goes well, $xof is an array of hashes, each representing an
# XObject corresponding to the <svg> elements in the file.

# Get a page and place the XObject.
my $page = $pdf->page;
$page->bbox( 0, 0, 595, 842 );	# A4
my $gfx = $page->gfx;

my $x = 0;			# left edge of page
my $y = 842;			# top edge of page

foreach ( @$xof ) {
    my $xo = $_->{xo};

    # Place it top left, at distance 10.
    my @bb = $xo->bbox;
    my $h = $bb[3];
    $gfx->object( $xo, $x+10, $y-10-$h );
    $y -= $h;
}

$pdf->save("sample.pdf");

__DATA__
<?xml version="1.0" standalone="no"?>
<svg width="200" height="250" version="1.1" xmlns="http://www.w3.org/2000/svg">
  <desc>Basic shapes</desc>
  <rect x="0.5" y="0.5" width="199" height="249"
        stroke="black" fill="none" stroke-width="1"/>
  <rect x="10" y="10" width="30" height="30" stroke="black"
        fill="transparent" stroke-width="5"/>
  <rect x="60" y="10" rx="10" ry="10" width="30" height="30"
        stroke="black" fill="transparent" stroke-width="5"/>

  <circle cx="30" cy="75" r="20"
          stroke="red" fill="transparent" stroke-width="5"/>
  <ellipse cx="80" cy="75" rx="20" ry="5"
           stroke="red" fill="transparent" stroke-width="5"/>

  <line x1="10" x2="50" y1="110" y2="150"
        stroke="orange" stroke-width="5"/>
  <polyline points="60 110 65 120 70 115 75 130 80 125 85 140 90 135 95 150 100 145"
            stroke="orange" fill="transparent" stroke-width="5"/>

  <polygon points="50 160 55 180 70 180 60 190 65 205 50 195 35 205 40 190 30 180 45 180"
           stroke="green" fill="transparent" stroke-width="5"/>

  <path d="M20,230 Q40,205 50,230 T90,230"
  fill="none" stroke="blue" stroke-width="5"/>
  <g fill="yellow" transform="translate(60,-5)">
    <path d="M 50,30 A 20,20 0,0,1 90,30 A 20,20 0,0,1 130,30
             Q 130,60 90,90 Q 50,60 50,30 z"
          id="heart" />
  </g>
  <use x="60" y="75"  xlink:href="#heart" fill="magenta" />
  <use x="60" y="155" xlink:href="#heart" fill="cyan"    />

</svg>
