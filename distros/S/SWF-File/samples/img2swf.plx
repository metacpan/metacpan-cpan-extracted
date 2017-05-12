#!/usr/bin/perl

use strict;

use SWF::File;
use SWF::Element;
use Image::Magick;
use Compress::Zlib;
use Getopt::Std;

my %opt;
getopts('ft', \%opt);

my ($imagefile, $swffile) = @ARGV;

unless (defined $imagefile) {
    print STDERR <<USAGE;
img2swf.plx - convert an image to a swf.
  perl img2swf.plx [-f] [-t] imagefile [swffile]
   -f: Force to convert to full color bitmap.
   -t: Keep transparency.
USAGE

    exit(1);
}

($swffile = $imagefile) =~s/\.[^.]+$/.swf/ unless defined $swffile;

my $image = Image::Magick->new;
$image->Read($imagefile);

my $height = $image->Get('height');
my $width = $image->Get('width');
die "Can't open $imagefile." if ($height == 0 and $width == 0);

my ($lossless, $tp);
if ($opt{t} and $image->Get('matte')) {
    $lossless = SWF::Element::Tag::DefineBitsLossless2->new;
    $tp=1;
} else {
    $lossless = SWF::Element::Tag::DefineBitsLossless->new;
    $tp=0;
}
$lossless->configure
    ( CharacterID => 1,
      BitmapWidth => $width,
      BitmapHeight => $height,
    );

if ((my $colors = $image->Get('colors'))>=256 or $opt{f}) {

    $lossless->BitmapFormat(5); # fullcolor

    my $d = deflateInit() or die "Can't open zlib stream."; 

    for(my $y = 0; $y<$height; $y++) {
	for(my $x = 0; $x<$width; $x++) {
	    my @rgba = split /,/, $image->Get("pixel[$x,$y]");
	    if (!$tp) {
		pop @rgba;
		unshift @rgba, 0;
	    } else {
		$rgba[3] = 255-$rgba[3];
		@rgba=@rgba[3,0..2];
	    }

	    my ($output, $status) = $d->deflate(pack('CCCC',@rgba)); # 4 bytes per pixel.
	    die "Compress error." unless $status == Z_OK;
	    $lossless->ZlibBitmapData->add($output);
	}
    }

    my ($output, $status) = $d->flush();
    die "Compress error." unless $status == Z_OK;
    $lossless->ZlibBitmapData->add($output);

} else {

    $lossless->BitmapFormat(3); # bitmap with colormap
    $lossless->BitmapColorTableSize($colors-1);

    my (%colors, $pixels);
    my $index = 0;
    my $pad = "\x00" x (4 - $width % 4);
    my $d = deflateInit() or die "Can't open zlib stream."; 

    for(my $y = 0; $y<$height; $y++) {
	for(my $x = 0; $x<$width; $x++) {
	    my $rgba;
	    unless (exists $colors{$rgba = $image->Get("pixel[$x,$y]")}) {
		$colors{$rgba} = pack('C',$index++);
	    }
	    $pixels .= $colors{$rgba};
	}
	$pixels .= $pad;
    }
    %colors = reverse %colors;
    $tp = $tp ? 'CCCC':'CCC';
    for my $k (sort keys %colors) {
	my @rgba = split /,/, $colors{$k};
	$rgba[3] = 255-$rgba[3];
	my ($output, $status) = $d->deflate(pack($tp, @rgba));
	die "Compress error." unless $status == Z_OK;
	$lossless->ZlibBitmapData->add($output);
    }
    my ($output, $status) = $d->deflate($pixels);
    die "Compress error." unless $status == Z_OK;
    $lossless->ZlibBitmapData->add($output);
    ($output, $status) = $d->flush();
    die "Compress error." unless $status == Z_OK;
    $lossless->ZlibBitmapData->add($output);
}

# create SWF.

my $swf = SWF::File->new($swffile);
$swf->FrameRate(15);
$swf->FrameSize(0,0,$width*20,$height*20);   # It can't set the same size???

SWF::Element::Tag::SetBackgroundColor->new(
     BackgroundColor => [
      Red => 128,
      Green => 255,
      Blue => 255,
     ],
)->pack($swf);

# lossless tag is packed here.

$lossless->pack($swf);

# define the same size rectangle filled with the bitmap.

SWF::Element::Tag::DefineShape2->new(
     ShapeID => 2,
     ShapeBounds => [
      Xmin => 0,
      Ymin => 0,
      Xmax => $width,
      Ymax => $height
     ],
     Shapes => [
      FillStyles => [
       FillStyleType => 0x40,
       BitmapID => 1,
      ],
      ShapeRecords => [
       [MoveDeltaX => 0, MoveDeltaY => 0, FillStyle0 => 1],
       [DeltaX => $width],
       [DeltaY => $height],
       [DeltaX => -$width],
       [DeltaY => -$height]
      ],
     ],
)->pack($swf);

SWF::Element::Tag::PlaceObject2->new(
     CharacterID => 2,
     Depth => 1,
     Matrix => [
      TranslateX => 0,
      TranslateY => 0,
      ScaleX => 20,
      ScaleY => 20,
     ],
)->pack($swf);

my $sf = SWF::Element::Tag::ShowFrame->new;
$sf->pack($swf);

SWF::Element::Tag::DoAction->new(
     Actions => [[Tag => 'ActionStop']],
)->pack($swf);

$sf->pack($swf);

SWF::Element::Tag::End->new->pack($swf);

$swf->close;
