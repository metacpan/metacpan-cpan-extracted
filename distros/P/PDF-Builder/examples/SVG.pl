#!/usr/bin/perl
#
use warnings;
use strict;
use PDF::Builder;
#use Data::Dumper; # for debugging
# $Data::Dumper::Sortkeys = 1; # hash keys in sorted order

our $VERSION = '3.027'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

my $showVB = 1; # 1 to show viewbox and any baseline
my $diags = 0;  # 1 to show diagnostic information
my $use_object = 1; # 1 to call object() [preferred method] rather than image()
my $in_dir = "examples/resources/SVG"; # use '.' if current dir

# SAMPLES USED HAVE BEEN MODIFIED TO USE CORE FONTS
my @svgs = (
    # handwritten SVGs by Phil Perry
    "$in_dir/ATS_flow.svg",  # needs scaling down to 92%
                             # if unscaled, goes off right margin
   #"$in_dir/attrPriority.svg",

    # SVG w/ inline PNG image       
   #"$in_dir/go.svg", 
   #"$in_dir/PNGfile.svg",   # requires external PNG file

    # SVG w/ inline GIF image 
    "$in_dir/GIFfilein.svg", # autoscales 1.33, resulting in bottom third
                             # missing if default position to LL=0,0
   #"$in_dir/GIFfile.svg",   # requires external GIF file

    # SVG w/ JPEG image
   #"$in_dir/JPEGfilein.svg",   # JPEG within file
   #"$in_dir/JPEGfile.svg",   # requires external JPEG file

    # SVG w/ TIFF image
   #"$in_dir/TIFFfilein.svg",   # TIFF within file  VERY SLOW
   #"$in_dir/TIFFfile.svg",   # requires external TIFF file

    # SVG w/ PNM image
   #"$in_dir/PBMfilein.svg",   # PBM within file VERY SLOW
   #"$in_dir/PBMfile.svg",   # requires external PBM file

    # SVG GnuPlot samples  
   #"$in_dir/GPhidden1.svg",
   #"$in_dir/GPpm3dsurface.svg", 
    "$in_dir/GPscatter5.svg",

    # SVG MathJax equations
    "$in_dir/MJdisplayNoTag.svg",
   #"$in_dir/MJinline.svg",

    # handwritten SVG bar codes by Phil Perry
    "$in_dir/QRcode.svg",  # QR OK, but a little heavy?
   #"$in_dir/UPC_A.svg",   # UPC very dense, need to zoom > 150% in AAR
           );

#my $pdf = PDF::Builder->new();
my $pdf = PDF::Builder->new('compress'=>'none');
if (!($pdf->LA_SVG())) {
    print "Unable to run SVG examples; SVGPDF is not installed.\n";
    exit;
}

my ($page, $text, $grfx);
my $page_num = 0;

my $name = $0;
$name =~ s/\.pl/.pdf/; # write in examples directory

my $magenta = '#ff00ff';
my $fs = 12;
my ($x, $y, $svg_in, $img);

while ($svg_in = shift(@svgs)) {
    $page_num++;
    print "==================================== processing input $svg_in for pg $page_num\n";
    $page = $pdf->page();
    $grfx = $page->gfx();
    $text = $page->text();
    $x = 0;  # left edge of page
    $y = 792; # top edge of US Letter page

    # ===== special stuff (scale to fit, etc.)
    if ($svg_in =~ m/PBMfilein/) {
        print "inlined PBM is very very slow!\n";
    }
    if ($svg_in =~ m/TIFFfilein/) {
        print "inlined TIFF is quite slow!\n";
    }
    my $scale = 1;
    if ($svg_in eq "$in_dir/ATS_flow.svg") { 
	$scale = 0.92;
    }
    # =====

    $img = $pdf->image_svg($svg_in);  # use default for all options
    # $img should be an array reference with one element

    my ($ULx, $ULy, $LRx, $LRy);
    if ($use_object) {
        $ULx = $x+10;
        $ULy = $y-10;
        # place upper left corner of object at 10,page top-10
        $grfx->object($img, $ULx, $ULy, $scale);
    } else {
	# use image() call, which simply throws it over the wall to object()
        $ULx = $x+10;
        $ULy = $y-10;
        # place upper left corner of object at 10,page top-10
	# note that with image(), scale instead of width and height
        $grfx->image($img, $ULx, $ULy, $scale);
    }

    if ($showVB) {
       # show where bounds of image (XO) are. ULx/y, LRx/y, baseline y
       my @imageVB = @{$img->[0]->{'imageVB'}};

       $LRx = $imageVB[2];
       $LRy = $imageVB[3];
       if ($LRx >= 8.5*72 && $showVB) {
	   # exceeds US Letter right edge
	   print "  right side of viewBox is at $LRx (off page)\n";
       }
       $grfx->save();
       $grfx->strokecolor("#ff00ff"); # magenta
       $grfx->linewidth(0.2);
       $grfx->rectxy($ULx,$ULy, $LRx,$LRy);
       # a baseline given?
       if ($imageVB[4] > $LRy) {
	   $grfx->move($ULx,$imageVB[4]);
	   $grfx->hline($ULx+25);
	   $grfx->move($LRx,$imageVB[4]);
	   $grfx->hline($LRx-25);
       }
       $grfx->stroke();
       $grfx->restore();
        
   } # outline viewbox
}

$pdf->save($name);
