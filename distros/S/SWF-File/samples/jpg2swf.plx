#!/usr/bin/perl

use strict;

use SWF::File;
use SWF::Element;

my ($imagefile, $swffile) = @ARGV;

unless (defined $imagefile) {
    print STDERR <<USAGE;
jpg2swf.plx - convert JPEG to swf.
  perl jpg2swf.plx JPEGfile [swffile]
USAGE

    exit(1);
}

($swffile = $imagefile) =~s/\.[^.]+$/.swf/ unless defined $swffile;

# read image to ImageMagick and get size.

open my $image, $ARGV[0];
binmode $image;
undef $/;
my ($jpegdata) = <$image>;

my $pos = 2;
while((my $s=substr($jpegdata, $pos, 2)) ne "\xff\xc0" and $pos < length($jpegdata)) {
    $pos += 2+unpack('n', substr($jpegdata, $pos+2,2));
}

die "Can't get the width and height of $imagefile.\n" if $pos>=length($jpegdata);
my $width = unpack('n', substr($jpegdata, $pos+7,2));
my $height = unpack('n', substr($jpegdata, $pos+5,2));

# create SWF.

my $swf = SWF::File->new($swffile);
$swf->FrameRate(15);
$swf->FrameSize(0,0,$width*20,$height*20);   # It can't set the same size???

SWF::Element::Tag::SetBackgroundColor->new(
     BackgroundColor => [
      Red => 255,
      Green => 255,
      Blue => 255,         # white
     ],
)->pack($swf);

SWF::Element::Tag::DefineBitsJPEG2->new(
     CharacterID => 1,
     JPEGData => SWF::Element::BinData->new($jpegdata),
)->pack($swf);

# define same size rectangle filled with the bitmap.

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
       [DeltaY => -$height],
      ],
     ],
)->pack($swf);

# place the rectangle.

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
SWF::Element::Tag::ShowFrame->new->pack($swf);
SWF::Element::Tag::DoAction->new(
     Actions => [[Tag => 'ActionStop']],
)->pack($swf);

SWF::Element::Tag::ShowFrame->new->pack($swf);
SWF::Element::Tag::End->new->pack($swf);

$swf->close;
