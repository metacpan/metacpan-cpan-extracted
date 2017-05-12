package SWF::Builder::Character::Bitmap::Lossless::GD;

use strict;
use GD 2.12;
use Carp;
use Compress::Zlib;

our @ISA = ('SWF::Builder::Character::Bitmap::Lossless');
our $VERSION = '0.04';

sub new {
    my ($class, $image) = @_;

    unless (ref($image)) {
	my $file = $image;
	$image = GD::Image->new($file) or croak "Can't create GD::Image object for $file";
    }

    my ($width, $height) = $image->getBounds;
    bless {
	_width  => $width,
	_height => $height,
	_colors => $image->colorsTotal||1<<24,
	_is_alpha => 1,
	_image => $image,
    }, $class;
}

sub _pack {
    my ($self, $stream) = @_;

    use bytes;

    my $gd = $self->{_image}->gd;
    my ($sx, $sy, $tcf, $colorsTotal, $transparent);
    my ($tag, $bm);
    my $d = deflateInit();

    if ($self->{_image}->isTrueColor) {
	my $header = substr($gd, 0, 11, '');
	($sx, $sy, $tcf, $transparent) = unpack('xxnncN', $header);
	$colorsTotal = 1<<24;
	$tag = SWF::Element::Tag::DefineBitsLossless2->new;
	$tag->BitmapFormat(5);
	$bm = $tag->ZlibBitmapData;
	for (my $i = 0; $i < length($gd); $i+=4) {
	    my $a = unpack('C', substr($gd, $i, 1));
	    if ($a) {
		$a = (127-$a) * 2;
		substr($gd, $i, 4) = pack('CCCC', $a, (map {$_*$a/255} unpack('CCC', substr($gd, $i+1, 3))));
	    } else {
		substr($gd, $i, 1) = "\xff";
	    }
	}
	my ($output, $status) = $d->deflate($gd);
	die "Compress error." unless $status == Z_OK;
	$bm->add($output);

    } else {
	my $header = substr($gd, 0, 13, '');
	($sx, $sy, $tcf, $colorsTotal, $transparent) = unpack('xxnncnN', $header);

	my $palette = substr($gd, 0, 256 * 4, '');
	my $is_alpha;
	for (my $i = 3; $i < $colorsTotal*4; $i += 4) {
	    my $a = substr($palette, $i, 1);
	    if ($a eq "\x00") {
		substr($palette, $i ,1) = "\xff";
		next;
	    }
	    $is_alpha = 1;
	    $a = (127-ord($a))*2; 
	    substr($palette, $i-3, 4) = pack('CCCC', (map {$_*$a/255} unpack('CCC', substr($palette, $i-3, 3))), $a);
	}
	my $palb;
	if ($transparent <= 1<<31) {
	    substr($palette, $transparent * 4, 4) = "\x00\x00\x00\x00";
	    $tag = SWF::Element::Tag::DefineBitsLossless2->new;
	    $palb = 4;
	} elsif ($is_alpha) {
	    $tag = SWF::Element::Tag::DefineBitsLossless2->new;
	    $palb = 4;
	} else {
	    $palette =~ s/(...)./$1/sg;
	    $tag = SWF::Element::Tag::DefineBitsLossless->new;
	    $palb = 3;
	}
	$tag->BitmapFormat(3);
	$tag->BitmapColorTableSize($colorsTotal-1);
	$bm = $tag->ZlibBitmapData;
	$palette = substr($palette, 0, $colorsTotal*$palb);
	my ($output, $status) = $d->deflate($palette);
	die "Compress error." unless $status == Z_OK;
	$bm->add($output);

	if (-$sx % 4) {
	    my $pad = "\x00" x (-$sx % 4);
	    for (my $i = 0; $i < length($gd); $i += $sx) {
		my ($output, $status) = $d->deflate(substr($gd, $i, $sx).$pad);
		die "Compress error." unless $status == Z_OK;
		$bm->add($output);
	    }
	} else {
	    my ($output, $status) = $d->deflate($gd);
	    die "Compress error." unless $status == Z_OK;
	    $bm->add($output);
	}
    }
    my ($output, $status) = $d->flush();
    die "Compress error." unless $status == Z_OK;
    $bm->add($output);
    $tag->configure( CharacterID => $self->{ID},
		     BitmapWidth => $sx,
		     BitmapHeight => $sy,
		     );
    $tag->pack($stream);
}

1;

