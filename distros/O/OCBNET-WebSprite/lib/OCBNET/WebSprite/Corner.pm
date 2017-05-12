###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
# this block can only contain one sprite
####################################################################################################
package OCBNET::WebSprite::Corner;
####################################################################################################
our $VERSION = '1.0.0';
####################################################################################################

use strict;
use warnings;

####################################################################################################

# a container is also a block
use base 'OCBNET::WebSprite::Container';

####################################################################################################

# create a new object
# ******************************************************************************
sub new
{

	# get package name, parent and options
	my ($pckg, $parent, $right, $bottom) = @_;

	# get object by calling super class
	my $self = $pckg->SUPER::new($parent);

	# set the options for the corner
	$self->{'is-right'} = $right;
	$self->{'is-bottom'} = $bottom;

	# return object
	return $self;

}

####################################################################################################

# getter methods for the specific options
# ******************************************************************************
sub isRight { return $_[0]->{'is-right'}; }
sub isBottom { return $_[0]->{'is-bottom'}; }

####################################################################################################

# calculate positions and dimensions
# ******************************************************************************
sub layout
{

	# get our object
	my ($self) = @_;

	# do nothing if empty
	return if $self->empty;

	# check if we really only have one child
	die "illegal state" if $self->length != 1;

	# get the only sprite in the corner
	my $sprite = $self->{'children'}->[0];

	# remove unnecessary paddings
	$sprite->paddingTop = 0 if not $self->isBottom;
	$sprite->paddingLeft = 0 if not $self->isRight;
	$sprite->paddingRight = 0 if $self->isRight;
	$sprite->paddingBottom = 0 if $self->isBottom;

	# fix position to zero
	$sprite->left = 0;
	$sprite->top = 0;

	# use the dimension of the sprite
	$self->width = $sprite->outerWidth;
	$self->height = $sprite->outerHeight;

	# return success
	return $self;

}
# EO sub layout


####################################################################################################
####################################################################################################
1;
