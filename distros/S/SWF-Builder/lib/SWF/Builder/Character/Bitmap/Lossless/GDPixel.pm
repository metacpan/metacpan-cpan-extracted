package SWF::Builder::Character::Bitmap::Lossless::GDPixel;

use strict;
use GD;
use Carp;

our @ISA = ('SWF::Builder::Character::Bitmap::Lossless');
our $VERSION = '0.03';

sub new {
    my ($class, $image) = @_;

    unless (ref($image)) {
	my $file = $image;
	$image = GD::Image->new($file) or croak "Can't create GD::Image object for $file";
    }

    my ($width, $height) = $image->getBounds;
    my $tp_i = $image->transparent;
    bless {
	_width  => $width,
	_height => $height,
	_colors => $image->colorsTotal||1<<24,
	_is_alpha => ($tp_i >= 0),
	_pixsub => sub {
	    my ($x, $y) = @_;
	    my $index = $image->getPixel($x, $y);
	    if ($index == $tp_i) {
		return (0,0,0,0);
	    } else {
		return ($image->rgb($index), 255);
	    }
	},
    }, $class;
}

1;

