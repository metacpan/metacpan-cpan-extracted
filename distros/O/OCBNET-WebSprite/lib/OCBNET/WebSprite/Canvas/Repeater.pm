###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
# static helper functions for canvas
####################################################################################################
package OCBNET::WebSprite::Canvas::Repeater;
####################################################################################################
our $VERSION = '1.0.0';
####################################################################################################

use strict;
use warnings;
use POSIX qw(ceil);

###################################################################################################

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter); }

# define our functions to be exported
BEGIN { our @EXPORT = qw(repeater); }

####################################################################################################

sub draw
{

	# canvas to draw
	my $canvas = shift;

	# where to draw
	my $canvas_left = shift;
	my $canvas_top = shift;
	my $canvas_width = shift;
	my $canvas_height = shift;

	# image to draw
	my $image = shift;

	# absolute offsets
	my $sprite_left = shift;
	my $sprite_top = shift;
	my $sprite_width = shift;
	my $sprite_height = shift;

	# which axis to repeat
	my $repeat_width = shift;
	my $repeat_height = shift;

	# assertion for valid dimensions
	# return if $sprite_width <= 0;
	# return if $sprite_height <= 0;
	# return if $canvas_width <= 0;
	# return if $canvas_height <= 0;

	# paint at actual sprite position exactly once
	my $stop_x = (my $start_x = $sprite_left) + $sprite_width;
	my $stop_y = (my $start_y = $sprite_top) + $sprite_height;

	# repeat sprite on x axis
	if ($repeat_width)
	{
		# get range of complete sprites that needs to be painted
		# even if only one pixel is shown we will draw a sprite there
		# the paint algorithm below will take care to crop if outside viewport
		my $delta_left = $sprite_left - $canvas_left;
		my $delta_right = $canvas_width - $stop_x;
		# warn "missing delta l/r ", $delta_left, "/", $delta_right;
		$start_x -= ceil($delta_left / $sprite_width) * $sprite_width;
		$stop_x += ceil($delta_right / $sprite_width) * $sprite_width;
		# warn "have to go l/r ", $start_x, "/", $stop_x;
	}

	# repeat sprite on y axis
	if ($repeat_height)
	{
		my $delta_top = $sprite_top - $canvas_top;
		my $delta_bottom = $canvas_height - $stop_y;
		# warn "missing delta t/b ", $delta_top, "/", $delta_bottom;
		$start_y -= ceil($delta_top / $sprite_height) * $sprite_height;
		$stop_y += ceil($delta_bottom / $sprite_height) * $sprite_height;
		# warn "have to go t/b ", $start_y, "/", $stop_y;
	}

	# draw (partial) image and repeating pattern on x axis
	for (my $x = $start_x; $x < $stop_x; $x += $sprite_width)
	{

		# draw (partial) image and repeating pattern on y axis
		for (my $y = $start_y; $y < $stop_y; $y += $sprite_height)
		{

			# gather crop options
			my %crop;

			# crop from left/top if below zero
			$crop{'x'} = $canvas_left - $x if ($x < $canvas_left);
			$crop{'y'} = $canvas_top - $y if ($y < $canvas_top);

			# crop dimension if outside viewport
			if ($x + $sprite_width >= $canvas_width)
			{ $crop{'width'} = $canvas_width - $x; }
			if ($y + $sprite_height >= $canvas_height)
			{ $crop{'height'} = $canvas_height - $y; }

			# lexical variable
			my $image = $image;
			# to crop the image
			if (scalar(%crop))
			{
				# create a clone
				$image = $image->clone;
				# crop the new image
				$image->Crop(%crop);
			}

			# draw image on canvas
			$canvas->Composite(
				image => $image,
				compose => 'over',
				x => $x + ($crop{'x'} || 0),
				y => $y + ($crop{'y'} || 0),
			);

		}
		# EO for $y

	}
	# EO for $x

}

# draw repeating sprites
# ******************************************************************************
sub repeater
{

	# get our object
	my ($self) = shift;

	# process all possible areas
	foreach my $area ($self->areas)
	{

		# ignore area if it's empty
		next if $area->empty;

		# get our own dimensions
		my $width = $self->width;
		my $height = $self->height;

		##########################################################
		# draw repeating patterns on the canvas
		##########################################################

		if (

			$area->isa('OCBNET::WebSprite::Fit') ||
			$area->isa('OCBNET::WebSprite::Edge') ||
			$area->isa('OCBNET::WebSprite::Stack') ||
			$area->isa('OCBNET::WebSprite::Corner')
		)
		{

			# paint repeating patterns on canvas
			foreach my $sprite ($area->children)
			{

				# absolute offset to canvas
				my $offset = $sprite->offset;

				# canvas options
				my @canvas = (
					0, # canvas_left
					0, # canvas_top
					$self->outerWidth, # canvas_width
					$self->outerHeight, # canvas_height
				);

				# sprite options
				my @sprite = (
					$offset->{'x'} + $sprite->paddingLeft, # sprite_left
					$offset->{'y'} + $sprite->paddingTop, # sprite_top
					$sprite->width, # sprite_width
					$sprite->height, # sprite_height
				);

				# only repeat in fixed area
				if ($sprite->isFixedX)
				{
					# make drawable canvas area smaller on x axis
					$canvas[0] = $offset->{'x'}; # canvas_left
					$sprite[0] = $canvas[0] + $sprite->paddingLeft; # sprite_left
					$canvas[2] = $offset->{'x'} + $sprite->outerWidth; # sprite_width
				}

				# only repeat in fixed area
				if ($sprite->isFixedY)
				{
					# make drawable canvas area smaller on y axis
					$canvas[1] = $offset->{'y'}; # canvas_left
					$sprite[1] = $canvas[1] + $sprite->paddingTop; # sprite_top
					$canvas[3] = $offset->{'y'} + $sprite->outerHeight; # sprite_height
				}

				# draw into canvas
				draw(
					# canvas to draw
					$self->{'image'},
					# where to draw
					@canvas,
					# image to draw
					$sprite->{'image'},
					# how to offset
					@sprite,
					# which axis to repeat
					$sprite->isRepeatX, # repeat_width
					$sprite->isRepeatY, # repeat_height
				);
			}
			# EO each sprite

		}
		# EO if fit/edge/stack

	}
	# EO each area

	# return success
	return $self;

}
# EO sub repeater

####################################################################################################
####################################################################################################
1;
