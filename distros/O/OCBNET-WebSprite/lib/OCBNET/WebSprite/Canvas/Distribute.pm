###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
# static helper functions for canvas
####################################################################################################
package OCBNET::WebSprite::Canvas::Distribute;
####################################################################################################
our $VERSION = '1.0.0';
####################################################################################################

use strict;
use warnings;

###################################################################################################

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter); }

# define our functions to be exported
BEGIN { our @EXPORT = qw(distribute); }

####################################################################################################

# distribute all sprites to areas
# according to their configurations
sub distribute
{

	# get our object
	my ($self) = @_;

	# a sprite that is enclosed can always be fitted. It's not
	# unnormal to have some offset for the image, but mostly the
	# container is nearly of the same size as the sprite. In some
	# cases the dev meant to use it left aligned in a big container.
	# then we should handle it as a left aligned image and put it
	# on the edge. This threshold determines when to fit and when
	# to put the sprite on the edge/stack area. Both padding will
	# be counted (outerWidth - width > threshold).
	my $threshold = 40;

	# get debug option from config hash
	my $debug = $self->{'config'}->{'debug'};

	##########################################################

	# reset area childrens (just in case)
	foreach my $area (@{$self->{'areas'}})
	{ $self->{$area}->{'children'} = []; }

	##########################################################

	# reset distributed flag on all sprites
	foreach my $sprite (@{$self->{'sprites'}})
	{ $sprite->{'distributed'} = 0; }

	##########################################################
	# DISTRIBUTERS
	##########################################################

	my @distributers = (

		# distribute one sprite into right top corner
		# optimum for height enclosed sprite left/bottom aligned
		# can remove height paddings and offset from top
		[ $self->{'corner-rt'}, 'isRepeating||alignRight||alignTop||isFixedX', 1 ],

		# distribute one sprite into left bottom corner
		# optimum for width enclosed sprite right/top aligned
		# can remove width paddings and offset from left
		[ $self->{'corner-lb'}, 'isRepeating||alignLeft||alignBottom||isFixedY', 1 ],

		# distribute one sprite into right bottom corners
		# optimum for non enclosed sprite left/top aligned
		# can remove all paddings and offset from left/top
		[ $self->{'corner-rb'}, 'isRepeating||alignRight||alignBottom||isFixedX||isFixedY', 1 ],

		# distribute one sprite into left top corner
		# optimum for enclosed sprite right/bottom aligned
		# can remove paddings and offset from left/top
		[ $self->{'corner-lt'}, 'isRepeating||alignLeft||alignTop||isFlexibleY||isFlexibleX', 1 ],

		# distribute the smaller items to the packed area to save precious space on the edges
		[ $self->{'middle'}, 'isFlexibleY||isFlexibleX||outerWidth-width>$threshold||outerHeight-height>$threshold' ],

		# distribute sprites into edges/stacks
		[ $self->{'stack-l'}, 'isRepeating||alignLeft||isFlexibleY||isFlexibleX' ],
		[ $self->{'stack-t'}, 'isRepeating||alignTop||isFlexibleY||isFlexibleX' ],
		[ $self->{'stack-b'}, 'isRepeating||alignBottom||isFlexibleX' ],
		[ $self->{'stack-r'}, 'isRepeating||alignRight||isFlexibleY' ],

		# distribute sprites into the packed center
		[ $self->{'middle'}, 'isFlexibleY||isFlexibleX' ],

		# distribute sprites into edges
		[ $self->{'edge-t'}, 'alignBottom||isFlexibleX' ],
		[ $self->{'edge-l'}, 'alignRight||isFlexibleY' ],
		[ $self->{'edge-r'}, 'alignLeft||isFlexibleY' ],
		[ $self->{'edge-b'}, 'alignTop||isFlexibleX' ],

	);

	##########################################################

	# process all distributers for all areas
	foreach my $distributer (@distributers)
	{

		# get the options for this area distributer
		my ($area, $excludes, $max) = @{$distributer};

		# replace certain keywords to be an actual object call
		$excludes =~ s/\b(?=is|not|align|width|height|outer|padding)/\$_[0]->/g;

		# eval the condition into a pre-compiled subroutine to call
		$excludes = eval sprintf 'sub { return (%s); };', $excludes;

		# propagate any eval errors
		# not needed but just in case
		die $@ if $@;

		# process each sprite to see if it should be
		# distributed into the currently checked area
		foreach my $sprite (@{$self->{'sprites'}})
		{

			# skip already distributed sprites
			next if $sprite->{'distributed'};

			# check for failed excludes
			next if $excludes->($sprite);

			# add sprite to area
			$area->add($sprite);

			# set the distributed flag
			$sprite->{'distributed'} = 1;

			# check if we have distributed enough sprites
			last if $max && scalar(@{$area->{'children'}}) >= $max;

		}
		# EO each sprite

	}
	# EO each distributer

	##########################################################

	# optimize space between repeaters
	@{$self->{'edge-l'}->{'children'}} =
	sort { $a->isRepeatX - $b->isRepeatX || $a->isFixedX - $b->isFixedX }
	@{$self->{'edge-l'}->{'children'}};

	# optimize space between repeaters
	@{$self->{'edge-r'}->{'children'}} =
	sort { $b->isRepeatX - $a->isRepeatX || $a->isFixedX - $b->isFixedX }
	@{$self->{'edge-r'}->{'children'}};

	# optimize space between repeaters
	@{$self->{'edge-t'}->{'children'}} =
	sort { $a->isRepeatY - $b->isRepeatY || $a->isFixedY - $b->isFixedY }
	@{$self->{'edge-t'}->{'children'}};

	# optimize space between repeaters
	@{$self->{'edge-b'}->{'children'}} =
	sort { $b->isRepeatY - $a->isRepeatY || $a->isFixedY - $b->isFixedY }
	@{$self->{'edge-b'}->{'children'}};

	##########################################################

	# unsupported sprites
	my $unsupported = 0;

	# check for sprite that have not been distributed
	# there are quite a few configurations that cannot
	# be handled - inform the user about these problems
	foreach my $sprite (@{$self->{'sprites'}})
	{
		# distributed are the ones we like
		next if $sprite->{'distributed'};
		# only print header warning once
		unless ($unsupported)
		{
			warn "\nWARNING: Some sprites have been configured to be included within a\n" .
			     "spriteset, but are not possible to distribute to any area, due to\n" .
			     "invalid styles (like repeating and/or beeing flexible in both axes)!\n\n";
		}
		# print each unsupported sprite to the console
		warn sprintf "  url(%s) enc(%s/%s), rep(%s/%s), pos(%s/%s)\n",
			substr($sprite->{'filename'}, - 25),
			$sprite->isFixedX, $sprite->isFixedY,
			$sprite->isRepeatX, $sprite->isRepeatY,
			$sprite->positionX, $sprite->positionY;
		# increase counter
		$unsupported ++;
	}

	# wait a second make user more
	# aware that some problem exists
	sleep 1 if $unsupported && $debug;

}
# EO sub distribute

####################################################################################################
####################################################################################################
1;
