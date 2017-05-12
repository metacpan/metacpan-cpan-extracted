###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
# static helper functions for canvas
####################################################################################################
package OCBNET::WebSprite::Canvas::Optimize;
####################################################################################################
our $VERSION = '1.0.0';
####################################################################################################

use strict;
use warnings;

###################################################################################################

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter); }

# define our functions to be exported
BEGIN { our @EXPORT = qw(optimize finalize); }

####################################################################################################

# load some helper functions for parsing
# ******************************************************************************
use OCBNET::CSS3::Regex::Numbers qw(fromPx);

####################################################################################################

# get the boxes some padding according to the sprite
# configuration (by looking at the background position)
# ******************************************************************************
sub optimize
{
	# get our object
	my ($self) = shift;

	# process each area in canvas
	# foreach my $area ($self->areas)
	{

		# process each sprite from area
		foreach my $sprite (@{$self->{'sprites'}})
		{

			# get associated selector from current sprite
			my $selector = $sprite->{'selector'} || next;

			# create dimensions object and fill it with
			# min, max and actual value set in css styles
			my %dim; foreach my $dim ('width', 'height')
			{
				my $val = fromPx($selector->style($dim) || 0);
				my $min = fromPx($selector->style('min-' . $dim));
				my $max = fromPx($selector->style('max-' . $dim));
				$val = $max if defined $max && $val < $max; # extend
				$val = $max if defined $max && $val > $max; # range
				$val = $min if defined $min && $val < $min; # range
				$dim{$dim} = { 'min' => $min, 'max' => $max, 'val' => $val };
			}

			# get the block padding from the css
			# left/right paddings behave different regarding
			# background-position, as left acts as an offset but
			# right does not, since right aligns on the outer edge
			# and we can only position backgrounds relative to top/left
			my $padding_top = fromPx($selector->style('padding-top') || 0) || 0;
			my $padding_left = fromPx($selector->style('padding-left') || 0) || 0;
			my $padding_right = fromPx($selector->style('padding-right') || 0) || 0;
			my $padding_bottom = fromPx($selector->style('padding-bottom') || 0) || 0;

			# adjust all three values for padding
			foreach my $key ('min', 'max', 'val')
			{
				# add the padding to get the actual outer dimensions
				$dim{'width'}->{$key} += $padding_left + $padding_right;
				$dim{'height'}->{$key} += $padding_top + $padding_bottom;
			}

			# sprite is left aligned
			if ($sprite->alignLeft)
			{
				# add some padding to offset the actual sprite
				$sprite->paddingLeft = $sprite->positionX;
				# add more padding to the right to make sure we will fill out the whole available width (if width is not set, result will be negative)
				$sprite->paddingRight = $dim{'width'}->{'val'} - $sprite->positionX - $sprite->width / $sprite->scaleX if $dim{'width'}->{'val'};
			}
			# is right but has fixed dimension
			# we can translate this to left align
			elsif ($sprite->isFixedX)
			{
				# problem is we cannot change position as we are not yet distributed!
				$sprite->paddingLeft = $dim{'width'}->{'val'} - $sprite->width / $sprite->scaleX;
			}

			# create padding if it's offset from top
			if ($sprite->alignTop)
			{
				# add some padding to offset the actual sprite
				$sprite->paddingTop = $sprite->positionY;
				# add more padding to the bottom to make sure we will fill out the whole available height (if height is not set, result will be negative)
				$sprite->paddingBottom = $dim{'height'}->{'val'} - $sprite->positionY - $sprite->height / $sprite->scaleY if $dim{'height'}->{'val'};
			}
			# is right but has fixed dimension
			elsif ($sprite->isFixedY)
			{
				# problem is we cannot change position as we are not yet distributed!
				$sprite->paddingTop = $dim{'height'}->{'val'} - $sprite->height / $sprite->scaleY;
			}

			# adjust the padding to account for scaling
			$sprite->paddingTop *= $sprite->scaleY;
			$sprite->paddingLeft *= $sprite->scaleX;
			$sprite->paddingRight *= $sprite->scaleX;
			$sprite->paddingBottom *= $sprite->scaleY;

			# make sure we dont have any negative paddings
			# fixes wrong calculation if no dimension is given
			# $sprite->paddingTop = 0 if $sprite->paddingTop < 0;
			# $sprite->paddingLeft = 0 if $sprite->paddingLeft < 0;
			# $sprite->paddingRight = 0 if $sprite->paddingRight < 0;
			# $sprite->paddingBottom = 0 if $sprite->paddingBottom < 0;

		}
		# EO each sprite

	}
	# Eo each area

	# make chainable
	return $self;

}
# EO sub optimize

###################################################################################################

# sprites have been distributed, so we now can
# start to translate bottom/right positioned sprites
# in fixed dimension boxes to top/left aligned sprites
# ******************************************************************************
sub finalize
{

	# get our object
	my ($self) = shift;

	# process all sprites on this canvas
	foreach my $sprite (@{$self->{'sprites'}})
	{

		# get associated selector from current sprite
		# my $selector = $sprite->{'selector'} || next;

		# is right aligned and has fixed dimension
		# this can be translated to a left alignment
		if ($sprite->alignRight && $sprite->isFixedX)
		{ $sprite->positionX = $sprite->paddingLeft / $sprite->scaleX; }

		# is bottom aligned and has fixed dimension
		# this can be translated to a top alignment
		if ($sprite->alignBottom && $sprite->isFixedY)
		{ $sprite->positionY = $sprite->paddingTop / $sprite->scaleY; }

		# add some safety margin
		$sprite->paddingTop += $sprite->scaleY;
		$sprite->paddingLeft += $sprite->scaleX;
		# add some more safety margin
		$sprite->paddingRight += $sprite->scaleX;
		$sprite->paddingBottom += $sprite->scaleY;

	}
	# EO each sprite

	# make chainable
	return $self;

}
# EO sub optimize

####################################################################################################
####################################################################################################
1;
