package SWF::Builder::Character::Bitmap;

use strict;
use bytes;

use Carp;
use SWF::Element;
use SWF::Builder::ExElement;
use SWF::Builder::Character;
use SWF::Builder::Character::Shape;

our $VERSION="0.044";

@SWF::Builder::Character::Bitmap::ISA = qw/ SWF::Builder::Character::Displayable /;

sub matrix {
  SWF::Builder::ExElement::MATRIX->new->scale(20);
}

sub place {
    my $self = shift;

    unless ($self->{_shapetag}) {
	$self->{_shapetag} = $self->{_parent}->new_shape
	    ->linestyle('none')
	    ->fillstyle($self, 'tiled', matrix())
	    ->box(0, 0, $self->{_width}, $self->{_height});
    }
    $self->{_shapetag}->place(@_);
}

####

package SWF::Builder::Character::Bitmap::Imported;

@SWF::Builder::Character::Bitmap::Imported::ISA = qw/ SWF::Builder::Character::Imported SWF::Builder::Character::Bitmap /;

sub place {
  Carp::croak "Can't place the imported bitmap because it's size is unknown";
}

####

package SWF::Builder::Character::Bitmap::Def;

@SWF::Builder::Character::Bitmap::Def::ISA = qw/ SWF::Builder::Character::Bitmap /;

sub width {
    shift->{_width};
}

sub height {
    shift->{_height};
}

sub get_bbox {
    my $self = shift;
    return (0, 0, $self->{_width}, $self->{_height});
}

####

package SWF::Builder::Character::Bitmap::JPEG;

use Compress::Zlib;
use Carp;

@SWF::Builder::Character::Bitmap::JPEG::ISA = qw/ SWF::Builder::Character::Bitmap::Def /;

sub new {
    my ($class, %param) = @_;

    my $self = bless { _is_alpha => 0 }, $class;
    $self->_init_character;
    $self->JPEGData($param{JPEGData}) if $param{JPEGData};
    $self->AlphaData($param{AlphaData}) if $param{AlphaData};
    $self->load_jpeg($param{JPEGFile}) if $param{JPEGFile};
    $self->load_alpha($param{AlphaFile}) if $param{AlphaFile};
    $self->Alpha($param{Alpha}) if $param{Alpha};
    $self;
}

sub JPEGData {
    my $self = shift;
    my $pos = 2;
    my $len = length($_[0]);
    $self->{_jpegdata} = $_[0];

    while((my $s=substr($_[0], $pos, 2)) ne "\xff\xc0" and $pos < $len) {
	$pos += 2+unpack('n', substr($_[0], $pos+2,2));
    }
    croak "Can't get the width and height of JPEG data" if $pos>=$len;
    @{$self}{qw/_width _height/} = unpack('nn', substr($_[0], $pos+5,4));
    undef $self->{_jpegfile};
    $self;
}

sub AlphaData {
    my ($self, $alphadata) = @_;
    $self->{_alphadata} = compress($alphadata) if defined $alphadata;
    undef $self->{_alphafile};
    $self->{_is_alpha} = defined $self->{_alphadata};
    $self;
}

sub Alpha {
    my ($self, $alpha) = @_;

    $alpha = pack('C', $alpha) x $self->{_width};
    $self->{_alphadata} = '';
    my $z = deflateInit() or croak "Can't create zlib stream ";
    for (my $c = 0; $c < $self->{_height}; $c++) {
	my ($out, $status) = $z->deflate(\$alpha);
	defined $out or croak "Zlib raised an error $status ";
	$self->{_alphadata} .= $out;
    }
    my ($out, $status) = $z->flush;
    defined $out or croak "Zlib raised an error $status ";
    $self->{_alphadata} .= $out;
    undef $self->{_alphafile};
    $self->{_is_alpha} = 1;
    $self;
}

sub load_jpeg {
    my ($self, $fn) = @_;

    $self->{_jpegfile} = $fn;
    undef $self->{_jpegdata};

    open my $f, '<', $fn or Carp::croak "Can't open $fn";
    binmode $f;

    my $s;
    seek($f, 2, 0);

  SEEK_SIZE:
    {
	{
	    read($f, $s, 4);
	    last SEEK_SIZE if $s =~ /^\xff\xc0/;
	    last if length($s)<4;
	    seek($f, unpack('n', substr($s, 2, 2))-2, 1);
	    redo;
	}
      Carp::croak "Can't get the width and height of $fn";
    }
    read($f, $s, 5);
    (undef, $self->{_height}, $self->{_width}) = unpack('cnn', $s);
    $self;
}

sub load_alpha {
    my ($self, $fn) = @_;

    $self->{_alphafile} = $fn;
    undef $self->{_alphadata};

    open my $f, '<', $fn or Carp::croak "Can't open $fn";
    binmode $f;
    $self->{_is_alpha} = 1;
    $self;
}

sub _pack {
    my ($self, $stream) = @_;
    my $tag;

    if ($self->{_alphadata} or $self->{_alphafile}) {
	$tag = SWF::Element::Tag::DefineBitsJPEG3->new
	    ( CharacterID => $self->{ID});
	if ($self->{_alphafile}) {
	    my $z = deflateInit() or croak "Can't create zlib stream ";
	    open my $af, "<", $self->{_alphafile} or Carp::croak "Can't open ".$self->{_alphafile};
	    binmode $af;
	    while(read($af, my $d, 4096) > 0) {
		my ($out, $status) = $z->deflate(\$d);
		defined $out or croak "Zlib raised an error $status ";
		$tag->BitmapAlphaData->add($out);
	    }
	    my ($out, $status) = $z->flush;
	    defined $out or croak "Zlib raised an error $status ";
	    $tag->BitmapAlphaData->add($out);
	} else {
	    $tag->BitmapAlphaData( $self->{_alphadata} );
	}
    } else {
	$tag = SWF::Element::Tag::DefineBitsJPEG2->new
	    ( CharacterID => $self->{ID});
    }

    if ($self->{_jpegfile}) {
	$tag->JPEGData->load($self->{_jpegfile});
    } else {
	$tag->JPEGData($self->{_jpegdata});
    }
    $tag->pack($stream);
}

####

package SWF::Builder::Character::Bitmap::Lossless;

use Carp;
use Compress::Zlib;

@SWF::Builder::Character::Bitmap::Lossless::ISA = qw/ SWF::Builder::Character::Bitmap::Def /;

sub new {
    my ($class, $obj, $type) = @_;

    unless (defined($type)) {
	if (UNIVERSAL::isa($obj, 'GD')) {
	    $type = 'GD';
	} elsif (UNIVERSAL::isa($obj, 'Image::Magick')) {
	    $type = 'ImageMagick';
	} elsif (not ref($obj)) {
	    if ($obj =~/\.png$/i or $obj =~/\.jpe?g$/i or $obj =~ /\.xpm$/i or $obj =~ /\.gd2$/i) {
		$type = 'GD';
	    } else {
		$type = 'ImageMagick';
	    }
	} else {
	    croak "Unknown bitmap object";
	}
    }

    my $package = "SWF::Builder::Character::Bitmap::Lossless::$type";
    eval "require $package";
    if ($@) {
	croak "Bitmap type '$type' is not supported" if $@=~/^Can\'t locate/;
	die;
    }
    my $self = $package->new($obj);
    $self->_init_character;
    $self;
}

sub _pack {
    my ($self, $stream) = @_;

    my ($width, $height) = @$self{qw/ _width _height /};
    my $tag = $self->{_is_alpha} ?
      SWF::Element::Tag::DefineBitsLossless2->new :
	SWF::Element::Tag::DefineBitsLossless->new;

    $tag->configure( CharacterID => $self->{ID},
		     BitmapWidth => $width,
		     BitmapHeight => $height,
		     );
    my $bm = $tag->ZlibBitmapData;
    my $pixsub = $self->{_pixsub};
    my $d = deflateInit();

    if (!$self->{_fullcolor} and $self->{_colors} <= 256) {
	$tag->BitmapFormat(3);   # ColorMap

	my (%colors, $pixels);
	my $index = 0;
	my $pad = "\x00" x (-$width % 4);
	my $tmpl = $self->{_is_alpha} ? 'CCCC':'CCC';
	for(my $y = 0; $y<$height; $y++) {
	    for(my $x = 0; $x<$width; $x++) {
		my ($r, $g, $b, $a) = $pixsub->($x,$y);
		$r = $r * $a / 255;
		$g = $g * $a / 255;
		$b = $b * $a / 255;
		my $rgba = pack($tmpl, $r, $g, $b, $a);
		unless (exists $colors{$rgba}) {
		    $colors{$rgba} = pack('C',$index++);
		}
		$pixels .= $colors{$rgba};
	    }
	    $pixels .= $pad;
	}

	%colors = reverse %colors;
	$index=0;
	for my $k (sort keys %colors) {
	    my ($output, $status) = $d->deflate($colors{$k});
	    die "Compress error." unless $status == Z_OK;
	    $bm->add($output);
	    $index++;
	}
	$tag->BitmapColorTableSize($index-1);
	my ($output, $status) = $d->deflate($pixels);
	die "Compress error." unless $status == Z_OK;
	$bm->add($output);
	($output, $status) = $d->flush();
	die "Compress error." unless $status == Z_OK;
	$bm->add($output);
    } else {
	$tag->BitmapFormat(5);   # Fullcolor pixmap
	for(my $y = 0; $y<$height; $y++) {
	    for(my $x = 0; $x<$width; $x++) {
		my ($r, $g, $b, $a) = $pixsub->($x,$y);
		$r = $r * $a / 255;
		$g = $g * $a / 255;
		$b = $b * $a / 255;
		my ($output, $status) = $d->deflate(pack('CCCC', $a,$r,$g,$b));
		die "Compress error." unless $status == Z_OK;
		$bm->add($output);
	    }
	}
    }
    my ($output, $status) = $d->flush();
    die "Compress error." unless $status == Z_OK;
    $bm->add($output);

    $tag->pack($stream);
}

1;
__END__

=head1 NAME

SWF::Builder::Character::Bitmap - SWF Bitmap object

=head1 SYNOPSIS

    my $jpeg = $mc->new_jpeg( 'picture.jpg' );
    $jpeg->place;

    use GD;
    $gd = GD::Image->newFromPng( 'tile.png' );
    my $bm = $mc->new_bitmap( $gd, 'GD' );
    my $shape = $mc->new_shape
                ->fillstyle($bm, 'tiled', $bm->matrix)
		->box(0, 0, 100, 100);

=head1 DESCRIPTION

SWF supports JPEG and lossless bitmaps.

=over 4

=item $jpg_bm = $mc->new_jpeg( JPEGFile => $filename / JPEGData => $jpegdata, AlphaFile => $filename / AlphaData => $alphadata / Alpha => $alpha )

=item $jpg_bm = $mc->new_jpeg( $filename )

returns a new JPEG bitmap. It can take named parameters as follows:

=over 4

=item JPEGFile / JPEGData

set a JPEG Data from a file and a binary data string, respectively.

=item AlphaFile / AlphaData / Alpha

set an alpha (transparency) data from a file, a binary data string, and a
single byte, respectively.
The alpha data is width x height length string of byte, 0(transparent) to
255(opaque). A single byte Alpha is expanded into the proper size.

=back

When you give a single parameter, it is regarded 
as the JPEG file name. Same as JPEGFile => $filename.

=item $jpg_bm->JPEGData/AlphaData/Alpha( $data )

set a JPEG/Alpha data.

=item $jpg_bm->load_jpeg/load_alpha( $filename )

load a JPEG/alpha data file.

=item $ll_bm = $mc->new_bitmap( $obj [, $type] )

returns a new lossless bitmap converted from a $type of $obj.
If $type is omitted, it is guessed.
If $obj is not an object, it is treated as a file name.

Acceptable types are as follows:

=over 4

=item GD

takes a GD::Image object.

=item ImageMagick

takes an Image::Magick object.

=item Custom

takes an array reference of [ $width, $height, $colors, $is_alpha, \&pixsub ].
$width and $height are the width and height of the bitmap.
$colors is a total number of colors of the bitmap. If it is under 256,
the bitmap is converted to colormapped image, otherwise 24-bit full color.
$is_alpha is a flag whether the bitmap has an alpha data.
&pixsub is a subroutine, which takes pixel coordinates ($x, $y) and returns
an array of the color data of the pixel, ($r, $g, $b, $a).

=back

=item $bm->width

returns the bitmap width.

=item $bm->hegiht

returns the bitmap height.

=item $bm->get_bbox

returns the bounding box of the bitmap, (0, 0, width, height).

=item $bm->matrix

returns a bitmap transformation matrix.

=item $bm_i = $bm->place( ... )

returns the display instance of the bitmap 
(to be exact, returns the instance of a box shape which filled with the bitmap).
See L<SWF::Builder>.

=back

=head1 COPYRIGHT

Copyright 2003 Yasuhiro Sasama (ySas), <ysas@nmt.ne.jp>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
