#!/usr/bin/perl

use v5.26;

#my $api = "PDF::Builder";	# or "PDF::API2";
my $api = "PDF::API2";	# or "PDF::Builder";
eval "require $api" || die($@);

use SVGPDF;

# Setup PDF document and a page.
my $pdf = $api->new;
my $page = $pdf->page;
$page->bbox( 0, 0, 595, 842 );	# A4
my $gfx = $page->gfx;
my $text = $page->text;

# Text font.
my $font = $pdf->font('Times-Roman');
my $fontsz = 12;

# SVG renderer.
my $svg = SVGPDF->new( $pdf, verbose => 0 );

# A place to start.
my $x = 10;
my $y = 700;

# Just for demo, we do renderings at different font sizes.
for ( 0..3 ) {

    # Some text...
    $text->translate( $x, $y );
    $text->font( $font, $fontsz );
    $x += $text->text("as given by the formula ");

    # Render the SVG.
    my $o = $svg->process( "mathjax.svg", fontsize => $fontsz );

    # Assume a single image, hence a single XObject.
    # Note that the results of process calls are stacked.
    my $xo = $o->[-1];

    # The dimensions of the XObject
    my $width   = $xo->{width};		# viewBox width
    my $height  = $xo->{height};	# viewBox height

    # Desired (design) width. May be relative to font size but will
    # already have been resolved.
    my $vwidth  = $xo->{vwidth};	# desired width
    my $vheight = $xo->{vheight};	# desired height

    # Scale factors to get viewBox dimensions to design dimensions.
    my $hscale = $vwidth / $width;
    my $vscale = $vheight / $height;

    # Place the object. The bbox determines the baseline.
    $gfx->object( $xo->{xo}, $x, $y, $hscale, $vscale );

    # Advance (for the rest of the content).
    $x += $vwidth;
    $text->translate( $x, $y );
    $x += $text->text(" (see appendix for details).");

    # For testing.
    $y -= 100;
    $x = 10;
    $fontsz += 2;
}

$pdf->save("mathjax.pdf");
