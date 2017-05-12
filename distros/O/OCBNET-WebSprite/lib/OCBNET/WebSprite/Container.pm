###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
# this is the base class for all children containers
# it can be drawn (is a block) and can have child nodes
####################################################################################################
package OCBNET::WebSprite::Container;
####################################################################################################
our $VERSION = '1.0.0';
####################################################################################################

use strict;
use warnings;
use POSIX qw(ceil);

####################################################################################################

use base 'OCBNET::WebSprite::Block';

####################################################################################################

use OCBNET::WebSprite::Math qw(lcm snap);

####################################################################################################

# create a new object
# called from children
# ******************************************************************************
sub new
{

	# get input arguments
	my ($pckg, $parent) = @_;

	# call constructor for block class
	my $self = $pckg->SUPER::new($parent);

	# only for debugging purposes
	$self->{'bg'} = "xc:transparent";

	# storage for children
	$self->{'children'} = [];

	# bless into package
	bless $self, $pckg;

}

####################################################################################################

# add more children to this block
# ******************************************************************************
sub add
{

	my ($self, $child) = @_;

	# add new child to our array
	push(@{$self->{'children'}}, $child);

	# attach ourself as parent
	$child->{'parent'} = $self;

	# return new number of children
	return scalar @{$self->{'children'}};

}
# EO sub add

####################################################################################################

# getter for all children in list context
# ******************************************************************************
sub children { return @{$_[0]->{'children'}}; }

# getter for number of childrens
# ******************************************************************************
sub length { return scalar @{$_[0]->{'children'}}; }

####################################################################################################

# check if this block is empty
# ******************************************************************************
sub empty
{

	# check if the number of children is zero
	return scalar @{$_[0]->{'children'}} == 0;

}
# EO sub empty

####################################################################################################

# layout all child nodes
# updates dimensions and positions
# ******************************************************************************
sub layout
{

	# get our object
	my ($self) = @_;

	# layout all children
	$_->layout foreach (@{$self->{'children'}});

	# we scale by our common scale factor
	# so this has to be here and not in block
	foreach my $sprite ($self->children)
	{
		snap ($sprite->{'width'}, $self->scaleX);
		snap ($sprite->{'height'}, $self->scaleY);

	}

	# return success
	return $self;

}
# EO sub layout


####################################################################################################
# return the least common multiple for scales
####################################################################################################

sub scaleX
{
	my ($self) = @_;
	my @factors = (1);
	if (defined $self->{'scale-x'})
	{ return $self->{'scale-x'}; }
	foreach my $sprite ($self->children)
	{ push(@factors, $sprite->scaleX); }
	my $rv = lcm(@factors);
	die $rv unless $rv =~ m/^\d+$/;
	return $self->{'scale-x'} = $rv;
}

sub scaleY
{
	my ($self) = @_;
	my @factors = (1);
	if (defined $self->{'scale-y'})
	{ return $self->{'scale-y'}; }
	foreach my $sprite ($self->children)
	{ push(@factors, $sprite->scaleY); }
	my $rv = lcm(@factors);
	die $rv unless $rv =~ m/^\d+$/;
	return $self->{'scale-y'} = $rv;
}

####################################################################################################

# draw and return image instance
# ******************************************************************************
sub draw
{

	# get our object
	my ($self) = @_;

	# initialize empty image
	$self->{'image'}->Set(matte => 'True');
	$self->{'image'}->Set(magick => 'png');
	$self->{'image'}->Set(size => $self->size);
	$self->{'image'}->ReadImage($self->{'bg'});
	$self->{'image'}->Quantize(colorspace=>'RGB');

	# process all sprites to draw them inside
	# their given viewport (crop any overflow)
	# this allows to repeat in both directions
	foreach my $sprite (@{$self->{'children'}})
	{

		# draw background on canvas
		if ($sprite->{'bg'})
		{
			$self->{'image'}->Composite(
				compose => 'over',
				y => $sprite->top + $sprite->paddingTop,
				x => $sprite->left + $sprite->paddingLeft,
				image => $sprite->{'img-bg'}
			);
		}

		# draw the actual image later
		# when everything is laid out

	}
	# EO each sprite

	# return the image instance
	return $self->{'image'};

}
# EO sub draw

####################################################################################################
####################################################################################################
1;