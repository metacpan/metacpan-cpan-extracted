###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
# this block stacks the sprites vertically
# or horizontally together (and aligned)
####################################################################################################
package OCBNET::WebSprite::Stack;
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
	my ($pckg, $parent, $stack_vert, $align_opp) = @_;

	# get object by calling super class
	my $self = $pckg->SUPER::new($parent);

	# align the the oppositioning side?
	$self->{'align-opp'} = $align_opp;

	# stack vertically or horizontally?
	$self->{'stack-vert'} = $stack_vert;

	# return object
	return $self;

}

####################################################################################################

# getter methods for the specific options
# ******************************************************************************
sub alignOpp { return $_[0]->{'align-opp'}; }
sub stackVert { return $_[0]->{'stack-vert'}; }

####################################################################################################

# calculate the dimensions and inner positions
# ******************************************************************************
sub layout
{

	# get our object
	my ($self) = @_;

	# process all sprites in this stack
	foreach my $sprite ($self->children)
	{
		# top/bottom edge/stack
		if ($self->stackVert)
		{
			# sprite has px position
			if ($sprite->alignLeft)
			{
				# never needs right margin
				$sprite->paddingRight = 0;
				# only optimize top edge/stack
				unless ($self->alignOpp)
				{
					# keep left margin if repeating
					# unless ($sprite->isRepeatX)
					{ $sprite->paddingLeft = 0; }
				}
			}
		}
		# left/right edge/stack
		else
		{
			# sprite has px position
			if ($sprite->alignTop)
			{
				# never needs bottom margin
				$sprite->paddingBottom = 0;
				# only optimize top edge/stack
				unless ($self->alignOpp)
				{
					# keep top margin if repeating
					# unless ($sprite->isRepeatY)
					{ $sprite->paddingTop = 0; }
				}
			}
		}
	}
	# EO each sprite

	# call container layout
	# calls layout on sprites
	$self->SUPER::layout;

	# declare positions
	my ($top, $left) = (0, 0);

	# declare dimensions
	my ($width, $height) = (0, 0);

	# process all sprites for layout
	foreach my $sprite ($self->children)
	{

		# get the sprite outer dimensions
		my $sprite_width = $sprite->outerWidth;
		my $sprite_height = $sprite->outerHeight;

		# stack sprites vertically
		if ($self->stackVert)
		{
			# increase the stack height
			$height += $sprite_height;
			# search biggest sprite width
			if ($width < $sprite_width)
			{ $width = $sprite_width; }
		}
		# or stack sprites horizontally
		else
		{
			# increase the stack width
			$width += $sprite_width;
			# search biggest sprite height
			if ($height < $sprite_height)
			{ $height = $sprite_height; }
		}

		# store sprite position
		$sprite->left = $left;
		$sprite->top = $top;

		# increase the offset
		if ($self->stackVert)
		{ $top += $sprite_height; }
		else { $left += $sprite_width; }

	}
	# EO each sprite

	# store dimensions
	$self->width = $width;
	$self->height = $height;

	# return here if no alignment is set
	return $self unless $self->alignOpp;

	# process all sprites for alignment
	foreach my $sprite ($self->children)
	{
		# stacks sprites vertically
		if ($self->stackVert)
		{
			# align this sprite to the oppositioning side
			$sprite->left = $self->outerWidth - $sprite->outerWidth;
		}
		# stacks sprites horizontally
		else
		{
			# align this sprite to the oppositioning side
			$sprite->top = $self->outerHeight - $sprite->outerHeight;
		}
	}

	# allow chaining
	return $self;

}
# EO sub layout

####################################################################################################
####################################################################################################
1;