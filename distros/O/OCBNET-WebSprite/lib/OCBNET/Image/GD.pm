###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-WebSprite (GPL3)
####################################################################################################
package OCBNET::Image::GD;
####################################################################################################
our $VERSION = '1.0.2';
####################################################################################################

use Carp;
use strict;
use warnings;

####################################################################################################

use GD;

####################################################################################################

sub new
{
	# create a dummy object
	# init first image later
	return bless {}, $_[0];
}

####################################################################################################
# read image from filepath
####################################################################################################

sub Read
{

	# get input arguments
	my ($pkg, $path) = @_;

	# initialize a new image from the file path
	my $self->{'image'} = GD::Image->new($path);
	# implement proper error handling here

	# true color image with alpha channel
	$self->{'image'}->alphaBlending(1);
	$self->{'image'}->trueColor(1);

	# mimic imagemagick
	return '';

}
# EO Read

####################################################################################################
# read image from data
####################################################################################################

sub BlobToImage
{

	# get input arguments
	my ($self, $blob) = @_;

	# initialize a new image from given blob
	$self->{'image'} = GD::Image->new($blob);

	# implement proper error handling here

	# true color image with alpha channel
	$self->{'image'}->alphaBlending(1);
	$self->{'image'}->trueColor(1);

	# mimic imagemagick
	return undef;

}
# EO BlobToImage

####################################################################################################
# write image to data
####################################################################################################

sub ImageToBlob
{

	# get input arguments
	my ($self) = @_;

	# make sure alpha channel is saved
	$self->{'image'}->saveAlpha(1);

	# return png data for image
	return $self->{'image'}->png;

}
# EO ImageToBlob

####################################################################################################
# Image-Magick Get interface
# Only implement base features
####################################################################################################

sub Get
{

	# get input arguments
	my ($self, $key) = @_;

	# so far only dimension getting is implemented
	if ($key eq 'height') { $self->{'image'}->height }
	elsif ($key eq 'width') { $self->{'image'}->width }
	else { Carp::croak "Get $key not implemented"; }

}
# EO Get

####################################################################################################
# Image-Magick Set interface
# Only implement base features
# Allocate new image on set size
####################################################################################################

sub Set
{

	# get input arguments
	my ($self, $key, $value) = @_;

	# main feature
	if ($key eq 'size')
	{
		# get dimensions from magick string
		my ($width, $height) = split /x/, $value, 2;
		# create new truecolor image with dimensions
		my $image = GD::Image->new($width, $height, 1);
		# make sure the background is fully transparent
		my $bkg = $image->colorAllocateAlpha(0, 0, 0, 127);
		$image->alphaBlending(0); # replace pixels fully
		$image->filledRectangle(0, 0, $width, $height, $bkg);
		$image->alphaBlending(1); # bleed pixel over now
		# assign main image object
		$self->{'image'} = $image;
	}

	# just ignore some parameters
	# not even sure what they do
	elsif ($key eq 'matte') { }
	elsif ($key eq 'magick') { }

	# everything else is considered a fatal error
	else { Carp::croak "Set $key not implemented" }

}
# EO Set

####################################################################################################
# just ignore some methods
####################################################################################################

sub Quantize { }

####################################################################################################
# used to draw background color
####################################################################################################

sub ReadImage
{

	# get input arguments
	my ($self, $value) = @_;

	# get the main image object
	my $image = $self->{'image'};
	# assertion that we have an image object
	die "Crop without image" unless $image;
	# fetch the image dimensions
	my $width = $image->width;
	my $height = $image->height;

	# background
	my $color;

	# match against specific image-magick syntax for rgba color
	if ($value =~ m/^xc:rgba\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+|0?\.\d+)\s*\)$/)
	{ $color = $image->colorAllocateAlpha(int($1), int($2), int($3), int(127*0.75)) }
	elsif ($value =~ m/^xc:transparent$/) { $color = $image->colorAllocateAlpha(0, 0, 0, 127) }
	else { Carp::croak "Invalid ReadImage color definition <$value>"; }

	# draw the background rectangle
	$image->alphaBlending(0); # bleed pixel fully
	$image->filledRectangle(0, 0, $width, $height, $color);
	$image->alphaBlending(1); # bleed pixel over now

	# mimic imagemagick
	return $self;

}
# EO ReadImage

####################################################################################################
# draw image over another
####################################################################################################

sub Composite
{

	# get input arguments
	my ($self, %options) = @_;

	# get composite action argument
	my $action = $options{'compose'};

	# only support over action
	if ($action eq 'over')
	{
		# get coordinates from options
		my $x = $options{'x'} || 0;
		my $y = $options{'y'} || 0;
		# get image to draw from options
		my $image = $options{'image'};
		# assertion that we have an image
		die "Compose without image" unless $image;
		# get OCBNET::Image object
		$image = $image->{'image'};
		# get dimensions to draw
		my $width = $image->width;
		my $height = $image->height;
		# copy the image in option into our own canvas at position
		$self->{'image'}->copy($image, $x, $y, 0, 0, $width, $height)
	}
	else
	{
		# give an error message (bad implementor)
		Carp::croak "Composite $action not implemented";
	}

	# mimic imagemagick
	return $self;

}
# EO Composite

####################################################################################################
# crop existing image
####################################################################################################

sub Crop
{

	# get input arguments
	my ($self, %options) = @_;

	# just return if nothing is to be done
	return $self unless scalar %options;

	# get the main image object
	my $image = $self->{'image'};

	# assertion that we have an image object
	die "Crop without image" unless $image;

	# get coordinates from options
	my $x = $options{'x'} || 0;
	my $y = $options{'y'} || 0;
	# fetch the image dimensions or defaults to rest
	my $width = $options{'width'} || $image->width - $x;
	my $height = $options{'height'} || $image->height - $y;

	# create a new image for cropped section
	my $crop = GD::Image->new($width, $height, 1);

	# init new image with transparent background
	my $bkg = $crop->colorAllocateAlpha(0, 0, 0, 127);
	$crop->alphaBlending(0); # replace pixels fully
	$crop->filledRectangle(0, 0, $width, $height, $bkg);
	# copy cropped section from source to destination
	$crop->copy($image, 0, 0, $x, $y, $width, $height);
	$crop->alphaBlending(1); # bleed pixel over now

	# re-assign cropped image
	$self->{'image'} = $crop;

	# return ourself
	return $self;

}
# EO Crop

####################################################################################################
# crop existing image
####################################################################################################

sub clone
{

	# get input arguments
	my ($self) = @_;

	# get the main image object
	my $image = $self->{'image'};
	# assertion that we have an image object
	die "Crop without image" unless $image;
	# fetch the image dimensions
	my $width = $image->width;
	my $height = $image->height;

	# create a new image for a complete copy
	my $copy = GD::Image->new($width, $height, 1);

	# init new image with transparent background
	my $bkg = $copy->colorAllocateAlpha(0, 0, 0, 127);
	$copy->alphaBlending(0); # replace pixels fully
	$copy->filledRectangle(0, 0, $width, $height, $bkg);
	# copy complete canvas from source to destination
	$copy->copy($image, 0, 0, 0, 0, $width, $height);
	$copy->alphaBlending(1); # bleed pixel over now

	# create new object with clone
	my $clone = { 'image' => $copy };

	# bless new object into package
	return bless $clone, ref $self;

}
# EO clone

####################################################################################################
####################################################################################################
1;
