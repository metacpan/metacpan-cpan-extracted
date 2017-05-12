###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
# load one sprite image into a block
####################################################################################################
package OCBNET::WebSprite::Sprite;
####################################################################################################
our $VERSION = '1.0.1';
####################################################################################################

use strict;
use warnings;

####################################################################################################

use base 'OCBNET::WebSprite::Block';

####################################################################################################

# constructor
sub new
{

	# shift class name
	my $pkg = shift;

	# call parent constructor first
	my $self = $pkg->SUPER::new();

	# extend instance
	%{$self} = (

		# from parent
		%{$self},

		# stack position
		'filename' => undef,
		# imagemagick object
		'image' => undef,
		# sprite dimensions
		'width' => undef,
		'height' => undef,
		# scale factors
		'scale-y' => 1,
		'scale-x' => 1,
		# background sizing
		'size-y' => undef,
		'size-x' => undef,
		# background repeating
		'repeat-y' => 0,
		'repeat-x' => 0,
		# is sprite enclosed
		'enclosed-x' => 0,
		'enclosed-y' => 0,
		# background position
		'position-y' => 'top',
		'position-x' => 'left',
		# background paddings
		'padding-top' => 0,
		'padding-left' => 0,
		'padding-right' => 0,
		'padding-bottom' => 0,

		# optional config
		%{$_[0] || {}}

	);
	# EO extend hash

	# normalize the repeat attribute (css is more explicit)
	$self->{'repeat-x'} = 1 if $self->{'repeat-x'} eq "repeat";
	$self->{'repeat-y'} = 1 if $self->{'repeat-y'} eq "repeat";

	# check if debug is enabled
	if ($self->{'debug'})
	{
		# add bg colors to sprites
		# conditional load Digest::MD5
		eval
		{
			# create unique string for config
			# this method makes the color static
			my $data = join '', grep { ! ref }
			                    grep { defined }
			                    map { $self->{$_} }
			                    sort keys %{$self};
			# try to load the digest module
			use Digest::MD5 qw(md5_hex);
			# create a md5 hex string
			my $digest = md5_hex($data);
			# create an rgba color out of it
			$self->{'bg'} = sprintf
				'xc:rgba(%d, %d, %d, 0.25)',
					hex(substr($digest, 0, 2)),
					hex(substr($digest, 4, 2)),
					hex(substr($digest, 6, 2));
		}
	}
	# EO if debug

	# create the image instance
	my $sprite = new OCBNET::Image;

	# check if there is a filename
	# this should probably be enforced
	if (my $path = $self->{'filename'})
	{
		# are we connected to a spriteset
		# so far only needed for reader
		if (defined $self->{'spriteset'})
		{
			# read the data via parent spriteset
			my $data = $self->{'spriteset'}->reader($path);
			# read image and store return value
			my $err = $sprite->BlobToImage($data);
			# check if there was any error reading the file
			die "Error from GraphicsMagick:\n", $err if $err;
		}
		else
		{
			# read image and store return value
			my $err = $sprite->Read($path);
			# check if there was any error reading the file
			die "Error from GraphicsMagick:\n", $err if $err;
		}
		# set dimensions readed from source file
		$self->width = $sprite->Get('width');
		$self->height = $sprite->Get('height');
		# save dimensions readed from source file
		$self->{'sprite-width'} = $sprite->Get('width');
		$self->{'sprite-height'} = $sprite->Get('height');
	}

	# assign image to instance
	# may not be initialized yet
	$self->{'image'} = $sprite;

	# calculate the x scaler if size-x is given
	# if the sprite is the background image in css
	# size-x would be taken from background-size-x
	if ($self->width && $self->{'size-x'})
	{
		# calculate the scale factor (inverse of a zoom factor)
		$self->{'scale-x'} = $self->width / $self->{'size-x'};
	}

	# calculate the x scaler if size-y is given
	# if the sprite is the background image in css
	# size-y would be taken from background-size-y
	if ($self->height && $self->{'size-y'})
	{
		# calculate the scale factor (inverse of a zoom factor)
		$self->{'scale-y'} = $self->height / $self->{'size-y'};
	}

	# check if we should paint a background
	# this has to be a separate image as I did
	# find a reliable way to do this otherwise
	if ($self->{'bg'})
	{
		# create a new graphics object
		my $bg = new OCBNET::Image;
		# set the size of the graphic
		$bg->Set(size => $self->size);
		# init image with solid color
		$bg->ReadImage($self->{'bg'});
		# we are operating in an rgb space
		$bg->Quantize(colorspace => 'RGB');
		# assign image to instance
		$self->{'img-bg'} = $bg;
	}
	# EO if bg

	# run debug assertions
	return $self->assert;

}
# EO constructor

####################################################################################################
# getter methods
####################################################################################################

# background sizing and scale factors
# ***************************************************************************************
sub sizeY { $_[0]->{'size-y'} || 1; }
sub sizeX { $_[0]->{'size-x'} || 1; }
sub scaleY { $_[0]->{'scale-y'} || 1; }
sub scaleX { $_[0]->{'scale-x'} || 1; }

# original dimensions of the loaded image
# ***************************************************************************************
sub spriteWidth { $_[0]->{'sprite-width'}; }
sub spriteHeight { $_[0]->{'sprite-height'}; }

# background position
# ***************************************************************************************
sub positionY : lvalue { $_[0]->{'position-y'}; }
sub positionX : lvalue { $_[0]->{'position-x'}; }

####################################################################################################
# status getter methods
####################################################################################################

sub isFixedX { $_[0]->{'enclosed-x'} }
sub isFixedY { $_[0]->{'enclosed-y'} }
sub isRepeatX { $_[0]->{'repeat-x'} }
sub isRepeatY { $_[0]->{'repeat-y'} }
sub isFlexibleX { not $_[0]->isFixedX }
sub isFlexibleY { not $_[0]->isFixedY }

sub isRepeating { $_[0]->{'repeat-x'} || $_[0]->{'repeat-y'} }
sub isRepeatingBoth { $_[0]->{'repeat-x'} && $_[0]->{'repeat-y'} }
sub notRepeating { not ($_[0]->{'repeat-x'} || $_[0]->{'repeat-y'}) }
sub notRepeatingBoth { not ($_[0]->{'repeat-x'} && $_[0]->{'repeat-y'}) }

# the alignment defines where a sprite can be distributed
# ***************************************************************************************
sub alignTop { !(defined $_[0]->{'position-y'} && $_[0]->{'position-y'} =~ m/^bottom$/i); }
sub alignLeft { !(defined $_[0]->{'position-x'} && $_[0]->{'position-x'} =~ m/^right$/i); }
sub alignRight { (defined $_[0]->{'position-x'} && $_[0]->{'position-x'} =~ m/^right$/i); }
sub alignBottom { (defined $_[0]->{'position-y'} && $_[0]->{'position-y'} =~ m/^bottom$/i); }

####################################################################################################
# debug only - remove in a later release
####################################################################################################

# return offset from root
# ***************************************************************************************
sub offset
{

	# get instance
	my ($self) = @_;

	# assert that the main position has been updated to the fit position
	die if defined $self->{'fit'}->{'x'} && $self->{'fit'}->{'x'} ne $self->left;
	die if defined $self->{'fit'}->{'y'} && $self->{'fit'}->{'y'} ne $self->top;

	# call base class method
	return $self->SUPER::offset;

}
# EO sub offset

####################################################################################################

# object assertions
sub assert
{

	# get instance
	my ($self) = @_;

	# assert that we are only using integer scale factors
	unless ($self->{'scale-x'} =~ m/^\d+$/)
	{
		warn sprintf "Illegal sprite: %s\n", $self->{'filename'};
		warn sprintf "Scale not valid: %s\n", $self->{'scale-x'};
		warn sprintf "Background X Dimension: %s\n", $self->{'size-x'};
		warn sprintf "Sprite X Resolution: %s\n", $self->width;
		Carp::confess "Abort, Fatal Error";
	}

	# assert that we are only using integer scale factors
	unless ($self->{'scale-y'} =~ m/^\d+$/)
	{
		warn sprintf "Illegal sprite: %s\n", $self->{'filename'};
		warn sprintf "Scale not valid: %s\n", $self->{'scale-y'};
		warn sprintf "Background Y Dimension: %s\n", $self->{'size-y'};
		warn sprintf "Sprite Y Resolution: %s\n", $self->height;
		Carp::confess "Abort, Fatal Error";
	}

	# call instance
	return $self;

}
# EO sub assert

####################################################################################################
# not sure if I should leave this in for the actual release?
####################################################################################################

# return debug text
# ***************************************************************************************
sub debug
{

	# get our object
	my ($self) = @_;

	require File::Spec;

	# debug filename
	return sprintf(
		'%s %s',
		substr(File::Spec->abs2rel( $self->{'filename'}, '.' ), - 16),
		$self->SUPER::debug
	);

}
# EO sub debug

####################################################################################################
####################################################################################################
1;
