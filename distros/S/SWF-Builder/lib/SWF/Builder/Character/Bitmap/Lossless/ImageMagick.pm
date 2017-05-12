package SWF::Builder::Character::Bitmap::Lossless::ImageMagick;

use strict;
use Image::Magick;

our @ISA = ('SWF::Builder::Character::Bitmap::Lossless');
our $VERSION = '0.02';

sub new {
    my ($class, $image) = @_;

    unless (ref($image)) {
	my $file = $image;
	$image = Image::Magick->new;
	$image->Read($file);
    }
    bless {
	_width  => $image->Get('width'),
	_height => $image->Get('height'),
	_colors => $image->Get('colors'),
	_is_alpha => $image->Get('matte'),
	_pixsub => sub {
	    my ($x, $y) = @_;
	    my  @rgba = map{$_ & 255} split /,/, $image->Get("pixel[$x,$y]");
	    $rgba[3] = 255-$rgba[3];
	    return @rgba;
	},
    }, $class;
}

1;
