###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
# this is the base class for all drawable items
# it can only be drawn and not hold any children
####################################################################################################
package OCBNET::WebSprite::Block;
####################################################################################################
our $VERSION = '1.0.1';
####################################################################################################

use strict;
use warnings;

####################################################################################################

# create a new object
# called from children
# ***************************************************************************************
sub new
{

	# get package name and parent
	my ($pckg, $parent) = @_;

	# create hash
	my $self = {

		# position
		'x' => 0,
		'y' => 0,

		# dimesion
		'w' => 0,
		'h' => 0,

		# padding for the box
		'padding-top' => 0,
		'padding-right' => 0,
		'padding-bottom' => 0,
		'padding-left' => 0,

		# the parent block node
		'parent' => $parent,

		# create an empty image
		# 'image' => new OCBNET::Image
		'image' => new OCBNET::Image

	};

	# bless into passed package
	return bless $self, $pckg;

}
# EO constructor

####################################################################################################
# getter and setter methods
####################################################################################################

# position of the block relative to the parent
# ***************************************************************************************
sub left : lvalue { $_[0]->{'x'} }
sub top : lvalue { $_[0]->{'y'} }

# dimension of the block
# ***************************************************************************************
sub width : lvalue { $_[0]->{'w'} }
sub height : lvalue { $_[0]->{'h'} }

# paddings for all four sides of the box
# ***************************************************************************************
sub paddingTop : lvalue { $_[0]->{'padding-top'} }
sub paddingLeft : lvalue { $_[0]->{'padding-left'} }
sub paddingRight : lvalue { $_[0]->{'padding-right'} }
sub paddingBottom : lvalue { $_[0]->{'padding-bottom'} }

# getter for combined results (used for graphicsmagick options)
# ***************************************************************************************
sub size { return join('x', $_[0]->width, $_[0]->height); }

# getter for outer dimensions (dimension plus padding from both sides of the box)
# ***************************************************************************************
sub outerWidth { return $_[0]->width + $_[0]->paddingLeft + $_[0]->paddingRight; }
sub outerHeight { return $_[0]->height + $_[0]->paddingTop + $_[0]->paddingBottom; }

####################################################################################################

# return offset from root
# ***************************************************************************************
sub offset
{

	# get instance
	my ($self) = @_;

	# get local offset
	my $left = $self->left;
	my $top = $self->top;

	# check if block has a parent
	# if so add parent offset too
	if ($self->{'parent'})
	{
		# get offset to root from parent
		# this will call offset recursively
		# since we don't have deep structures normally
		# it is ok, but convert it to a loop otherwise
		my $offset = $self->{'parent'}->offset();
		# sum up the total offset for both axes
		$left += $offset->{'x'}; $top += $offset->{'y'};
	}
	# EO if parent

	# return point
	return {
		'x' => $left,
		'y' => $top
	};

}
# EO sub getPosition

####################################################################################################
# event handler for layout
####################################################################################################

# set width and height to the outer dimension
# these values are mainly needed by the packer
sub layout
{

	# get instance
	my ($self) = @_;

	# padding does not make any sense if the
	# block is aligned to the opposite side
	$self->paddingLeft = 0 if $self->alignRight;
	$self->paddingRight = 0 if $self->alignRight;
	$self->paddingTop = 0 if $self->alignBottom;
	$self->paddingBottom = 0 if $self->alignBottom;

	# set the values for the outer dimension
	$self->{'width'} = $self->outerWidth;
	$self->{'height'} = $self->outerHeight;

	# return instance
	return $self;

}
# EO sub layout

####################################################################################################
# event handler for drawing
####################################################################################################

# just returns the image instance
sub draw { return $_[0]->{'image'}; }

####################################################################################################
# not sure if I should leave this in for the actual release?
####################################################################################################

sub debug
{

	# get our object
	my ($self) = @_;

	# get absolute position from root
	my $offset = $self->offset();

	# debug position
	return sprintf(
		'POS: %s/%s (%sx%s|%sx%s) [PAD: %s,%s,%s,%s] @ %s/%s => %s/%s',
		$self->left, $self->top,
		$self->width, $self->height,
		$self->outerWidth, $self->outerHeight,
		$self->paddingTop, $self->paddingRight,
		$self->paddingBottom, $self->paddingLeft,
		$self->scaleX, $self->scaleY,
		$offset->{'x'}, $offset->{'y'},
	);

}
# EO sub debug

####################################################################################################
####################################################################################################
1;