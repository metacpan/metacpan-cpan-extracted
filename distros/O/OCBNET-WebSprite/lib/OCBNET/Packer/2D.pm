###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
# https://github.com/jakesgordon/bin-packing/blob/master/js/packer.growing.js
# Perl implementation by marcel.greter@ocbnet.ch - same license as original
###################################################################################################
package OCBNET::Packer::2D;
####################################################################################################
our $VERSION = '1.0.0';
###################################################################################################

use strict;
use warnings;

###################################################################################################

sub new
{

	return bless {};

}

sub fit
{

	my ($self, $blocks) = @_;

	@{$blocks} = sort {
		($b->{'width'} > $b->{'height'} ? $b->{'width'} : $b->{'height'}) -
		($a->{'width'} > $a->{'height'} ? $a->{'width'} : $a->{'height'})
	} @{$blocks};

	my ($node, $block);

	my $len = scalar(@{$blocks});

	my $w = $len > 0 ? $blocks->[0]->{'width'} : 0;
	my $h = $len > 0 ? $blocks->[0]->{'height'} : 0;

	$self->{'root'} =
	{
		'x' => 0,
		'y' => 0,
		'width' => $w,
		'height' => $h
	};

	for (my $n = 0; $n < $len ; $n++)
	{

		my $block = $blocks->[$n];

		if ($node = $self->findNode($self->{'root'}, $block->{'width'}, $block->{'height'}))
		{
			$block->{'fit'} = $self->splitNode($node, $block->{'width'}, $block->{'height'});
		}
		else
		{
			$block->{'fit'} = $self->growNode($block->{'width'}, $block->{'height'});
		}
	}

	return 1;

};

sub findNode
{

	my ($self, $root, $w, $h) = @_;

	return $self->findNode($root->{'right'}, $w, $h) || $self->findNode($root->{'down'}, $w, $h) if $root->{'used'};

	return $root if (($w <= $root->{'width'}) && ($h <= $root->{'height'}));

	return undef;

}

sub splitNode
{

	my ($self, $node, $w, $h) = @_;

	$node->{'used'} = 1;

	$node->{'down'} =
	{
		'x' => $node->{'x'},
		'width' => $node->{'width'},
		'y' => $node->{'y'} + $h,
		'height' => $node->{'height'} - $h
	};

	$node->{'right'} = {
		'y' => $node->{'y'},
		'height' => $node->{'height'},
		'x' => $node->{'x'} + $w,
		'width' => $node->{'width'} - $w,
	};

	return $node;

}

sub growNode
{

	my ($self, $w, $h) = @_;

	my $canGrowDown = ($w <= $self->{'root'}->{'width'});
	my $canGrowRight = ($h <= $self->{'root'}->{'height'});

	# attempt to keep square-ish by growing right when height is much greater than width
	my $shouldGrowRight = $canGrowRight && ($self->{'root'}->{'height'} >= ($self->{'root'}->{'width'} + $w));
	# attempt to keep square-ish by growing down when width is much greater than height
	my $shouldGrowDown = $canGrowDown && ($self->{'root'}->{'width'} >= ($self->{'root'}->{'height'} + $h));

	return $self->growRight($w, $h) if ($shouldGrowRight);
	return $self->growDown($w, $h) if ($shouldGrowDown);
	return $self->growRight($w, $h) if ($canGrowRight);
	return $self->growDown($w, $h) if ($canGrowDown);

	# need to ensure sensible root
	# starting size to avoid this
	return undef;

}

sub growRight
{

	my ($self, $w, $h) = @_;

	$self->{'root'} =
	{
		'x' => 0,
		'y' => 0,
		'used' => 1,
		'height' => $self->{'root'}->{'height'},
		'width' => $self->{'root'}->{'width'} + $w,
		'down' => $self->{'root'},
		'right' =>
		{
			'y' => 0,
			'width' => $w,
			'height' => $self->{'root'}->{'height'},
			'x' => $self->{'root'}->{'width'}
		}
	};

	my $node = $self->findNode($self->{'root'}, $w, $h);

	return $node ? $self->splitNode($node, $w, $h) : undef;

 };

sub growDown
{

	my ($self, $w, $h) = @_;

	$self->{'root'} =
	{
		'x' => 0,
		'y' => 0,
		'used' => 1,
		'width' => $self->{'root'}->{'width'},
		'height' => $self->{'root'}->{'height'} + $h,
		'right' => $self->{'root'},
		'down' =>
		{
			'x' => 0,
			'height' => $h,
			'width' => $self->{'root'}->{'width'},
			'y' => $self->{'root'}->{'height'}
		}
	};

	my $node = $self->findNode($self->{'root'}, $w, $h);

	return $node ? $self->splitNode($node, $w, $h) : undef;

};

return 1;

__DATA__

This is a binary tree based bin packing algorithm that is more complex than
the simple Packer (packer.js). Instead of starting off with a fixed width and
height, it starts with the width and height of the first block passed and then
grows as necessary to accomodate each subsequent block. As it grows it attempts
to maintain a roughly square ratio by making 'smart' choices about whether to
grow right or down.

When growing, the algorithm can only grow to the right OR down. Therefore, if
the new block is BOTH wider and taller than the current target then it will be
rejected. This makes it very important to initialize with a sensible starting
width and height. If you are providing sorted input (largest first) then this
will not be an issue.

A potential way to solve this limitation would be to allow growth in BOTH
directions at once, but this requires maintaining a more complex tree
with 3 children (down, right and center) and that complexity can be avoided
by simply chosing a sensible starting block.

Best results occur when the input blocks are sorted by height, or even better
when sorted by max(width,height).

Inputs:
------

blocks: array of any objects that have .w and .h attributes

Outputs:
-------

marks each block that fits with a .fit attribute pointing to a
node with .x and .y coordinates

Example:
-------

my $blocks = [
  { w => 100, h => 100 },
  { w => 100, h => 100 },
  { w => 80, h => 80 },
  { w => 80, h => 80 },
  ...
];

my $packer = new OCBNET::Packer::2D();

$packer->fit($blocks);

foreach my $block (@{$blocks})
{
	# skip unfitted blocks
	next unless $block->{'fit'};
	# get the position and dimension
	my $x = $block->{'fit'}->{'x'};
	my $y = $block->{'fit'}->{'y'};
	my $w = $block->{'fit'}->{'w'};
	my $h = $block->{'fit'}->{'h'};
}
