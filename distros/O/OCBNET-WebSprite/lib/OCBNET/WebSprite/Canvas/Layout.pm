###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
# static helper functions for canvas
####################################################################################################
package OCBNET::WebSprite::Canvas::Layout;
####################################################################################################
our $VERSION = '1.0.0';
####################################################################################################

use strict;
use warnings;

###################################################################################################

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter); }

# define our functions to be exported
BEGIN { our @EXPORT = qw(layout snap); }

####################################################################################################

use OCBNET::WebSprite::Math qw(lcm snap factors);

####################################################################################################

# layout all child nodes
# updates dimensions and positions
# ******************************************************************************
sub layout
{

	# get our object
	my ($self) = shift;

	##########################################################
	# CALL LAYOUT ON EACH AREA
	##########################################################


	# call layout method on all areas
	$_->layout(@_) foreach ($self->areas);

	##########################################################
	# GET MULTIPLIERS FOR DIMENSIONS AND REPEATING
	##########################################################

	# declare repating arrays
	my (%repeat_x, %repeat_y);

	# process all sprites in canvas
	foreach my $sprite ($self->sprites)
	{

		# skip not distributed sprites
		next unless $sprite->{'distributed'};

		# make sure we can repeat this sprite perfectly
		if ($sprite->isRepeatX && $sprite->isFlexibleX)
		{
			my @factors = factors($sprite->width);
			my %factors; ++ $factors{$_} foreach @factors;
			foreach (keys %factors)
			{
				$repeat_x{$_} = 0 unless exists $repeat_x{$_};
				next if $repeat_x{$_} > $factors{$_};
				$repeat_x{$_} = $factors{$_};
			}
		}

		# make sure we can repeat this sprite perfectly
		if ($sprite->isRepeatY && $sprite->isFlexibleY)
		{

			my @factors = factors($sprite->height);
			my %factors; ++ $factors{$_} foreach @factors;
			foreach (keys %factors)
			{
				$repeat_y{$_} = 0 unless exists $repeat_y{$_};
				next if $repeat_y{$_} > $factors{$_};
				$repeat_y{$_} = $factors{$_};
			}
		}

	}
	# EO each sprite

	# calculate the lowest denominator for repeating snaping values
	my $repeat_x = 1; $repeat_x *= $_ ** $repeat_x{$_} foreach keys %repeat_x;
	my $repeat_y = 1; $repeat_y *= $_ ** $repeat_y{$_} foreach keys %repeat_y;

	##########################################################
	# GET LIMITS FROM SNAPPED ELEMENTS
	##########################################################

	my $col1_snap_w = lcm(
		$self->{'edge-l'}->scaleX,
		$self->{'stack-l'}->scaleX,
		$self->{'corner-lb'}->scaleX,
		$self->{'corner-lt'}->scaleX
	);
	my $row1_snap_h = lcm(
		$self->{'edge-t'}->scaleY,
		$self->{'stack-t'}->scaleY,
		$self->{'corner-rt'}->scaleY,
		$self->{'corner-lt'}->scaleY
	);

	my $col2_snap_w = lcm(
		$self->{'stack-t'}->scaleX,
		$self->{'middle'}->scaleX,
		$self->{'stack-b'}->scaleX
	);
	my $row2_snap_h = lcm(
		$self->{'stack-l'}->scaleY,
		$self->{'middle'}->scaleY,
		$self->{'stack-r'}->scaleY
	);

	my $col3_snap_w = $self->{'edge-t'}->scaleX;
	my $row3_snap_h = $self->{'edge-l'}->scaleY;
	my $col4_snap_w = $self->{'edge-b'}->scaleX;
	my $row4_snap_h = $self->{'edge-r'}->scaleY;

	my $col_snap_last_w = lcm(
		$self->{'edge-r'}->scaleX,
		$self->{'stack-r'}->scaleX,
		$self->{'corner-rb'}->scaleX,
		$self->{'corner-rt'}->scaleX
	);

	my $row_snap_last_h = lcm(
		$self->{'edge-b'}->scaleY,
		$self->{'stack-b'}->scaleY,
		$self->{'corner-lb'}->scaleY,
		$self->{'corner-rb'}->scaleY
	);

	my $col_snap_w = lcm(
		$repeat_x,
		$col1_snap_w,
		$col2_snap_w,
		$col3_snap_w,
		$col4_snap_w,
		$col_snap_last_w
	);

	my $row_snap_h = lcm(
		$repeat_y,
		$row1_snap_h,
		$row2_snap_h,
		$row3_snap_h,
		$row4_snap_h,
		$row_snap_last_h
	);

	##########################################################
	# GET LIMITS FROM SNAPPED ELEMENTS
	##########################################################

	use List::Util qw[min max];

	my $col1_w = max(
		$self->{'edge-l'}->outerWidth,
		$self->{'stack-l'}->outerWidth,
		$self->{'corner-lb'}->outerWidth,
		$self->{'corner-lt'}->outerWidth
	);

	my $row1_h = max(
		$self->{'edge-t'}->outerHeight,
		$self->{'stack-t'}->outerHeight,
		$self->{'corner-rt'}->outerHeight,
		$self->{'corner-lt'}->outerHeight
	);

	snap ($col1_w, $col1_snap_w);
	snap ($row1_h, $row1_snap_h);

	my $col2_w = max(
		$self->{'stack-t'}->outerWidth,
		$self->{'middle'}->outerWidth,
		$self->{'stack-b'}->outerWidth
	);
	my $row2_h = max(
		$self->{'stack-l'}->outerHeight,
		$self->{'middle'}->outerHeight,
		$self->{'stack-r'}->outerHeight
	);

	snap ($col2_w, $col2_snap_w);
	snap ($row2_h, $row2_snap_h);

	my $col3_w = $self->{'edge-t'}->outerWidth;
	my $row3_h = $self->{'edge-l'}->outerHeight;
	my $col4_w = $self->{'edge-b'}->outerWidth;
	my $row4_h = $self->{'edge-r'}->outerHeight;

	snap ($col3_w, $col3_snap_w);
	snap ($row3_h, $row3_snap_h);
	snap ($col4_w, $col4_snap_w);
	snap ($row4_h, $row4_snap_h);

	my $col_last_w = max(
		$self->{'edge-r'}->outerWidth,
		$self->{'stack-r'}->outerWidth,
		$self->{'corner-rb'}->outerWidth,
		$self->{'corner-rt'}->outerWidth
	);

	my $row_last_h = max(
		$self->{'edge-b'}->outerHeight,
		$self->{'stack-b'}->outerHeight,
		$self->{'corner-lb'}->outerHeight,
		$self->{'corner-rb'}->outerHeight
	);

	my $col1_x = $col1_w;
	my $row1_y = $row1_h;

	my $col2_x = $col1_x + $col2_w;
	my $row2_y = $row1_y + $row2_h;

	# make sure both sides will fit our repeating pattern
	# this can blow up the sprite by quite some factor if your image
	# dimensions have lots of different factors in it, if they are all
	# about the same size and not too big, this should work quite well
	my $snap_w = $col2_x + $col3_w + $col4_w + $col_last_w;
	my $snap_h = $row2_y + $row3_h + $row4_h + $row_last_h;
	snap(my $snapped_w = $snap_w, $repeat_x);
	snap(my $snapped_h = $snap_h, $repeat_y);
	$col2_x += $snapped_w - $snap_w;
	$row2_y += $snapped_h - $snap_h;

	my $col3_x = $col2_x + $col3_w;
	my $col4_x = $col3_x + $col4_w;

	my $row3_y = $row2_y + $row3_h;
	my $row4_y = $row3_y + $row4_h;

	##########################################################
	# CALCULATE LAYOUT
	##########################################################

	my $width = 0;
	my $height = 0;

	##########################################################
	# we have 13 areas, so 26 positions to set
	##########################################################

	# leave the first row in place (8)
	$self->{'corner-lt'}->top = 0;
	$self->{'corner-lt'}->left = 0;
	$self->{'stack-t'}->top = 0;
	$self->{'stack-l'}->left = 0;
	$self->{'edge-t'}->top = 0;
	$self->{'edge-l'}->left = 0;
	$self->{'corner-rt'}->top = 0;
	$self->{'corner-lb'}->left = 0;

	##########################################################

	# move the second row aways (6)
	$self->{'stack-l'}->top = $row1_y;
	$self->{'middle'}->top = $row1_y;
	$self->{'stack-r'}->top = $row1_y;
	$self->{'stack-t'}->left = $col1_x;
	$self->{'middle'}->left = $col1_x;
	$self->{'stack-b'}->left = $col1_x;

	##########################################################

	# move the third row aways (4)
	$self->{'edge-l'}->top = $row2_y;
	$self->{'edge-r'}->top = $row3_y;
	$self->{'edge-t'}->left = $col2_x;
	$self->{'edge-b'}->left = $col3_x;

	##########################################################

	my $w = $width = $self->width = $col4_x + $col_last_w;
	my $h = $height = $self->height = $row4_y + $row_last_h;

	snap ($w, $repeat_x);
	snap ($h, $repeat_y);

	die "width invalid: $width $w" if $w != $width;
	die "height invalid: $height $h" if $h != $height;

	##########################################################

	# move the fourth row aways (8)
	# align them to the right / bottom
	$self->{'corner-rb'}->top = $self->outerHeight - $self->{'corner-rb'}->outerHeight;
	$self->{'corner-rb'}->left = $self->outerWidth - $self->{'corner-rb'}->outerWidth;
	$self->{'stack-b'}->top = $self->outerHeight - $self->{'stack-b'}->outerHeight;
	$self->{'stack-r'}->left = $self->outerWidth - $self->{'stack-r'}->outerWidth;
	$self->{'edge-b'}->top = $self->outerHeight - $self->{'edge-b'}->outerHeight;
	$self->{'edge-r'}->left = $self->outerWidth - $self->{'edge-r'}->outerWidth;
	$self->{'corner-lb'}->top = $self->outerHeight - $self->{'corner-lb'}->outerHeight;
	$self->{'corner-rt'}->left = $self->outerWidth - $self->{'corner-rt'}->outerWidth;

	##########################################################
	# RE-ALIGN WIDGETS AFTER SNAPPING
	##########################################################

	# layout all children
	foreach my $area ($self->areas)
	{

		# ignore area if it's empty
		next if $area->empty;

		# adjust layout only for stacked (repeating) elements
		next unless $area->isa('OCBNET::WebSprite::Stack');

		# re-align the sub area
		if ($area->alignOpp)
		{
			if ($area->stackVert)
			{ $area->left = $self->width - $area->width; }
			else { $area->top = $self->height - $area->height; }
		}

	}
	# EO each area

	# return success
	return $self;

}
# EO sub layout

####################################################################################################
####################################################################################################
1;
