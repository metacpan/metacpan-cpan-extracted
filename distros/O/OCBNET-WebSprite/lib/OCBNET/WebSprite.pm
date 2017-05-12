###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-WebSprite (GPL3)
####################################################################################################
package OCBNET::WebSprite;
####################################################################################################
our $VERSION = '1.0.2';
####################################################################################################

use Carp;
use strict;
use warnings;

####################################################################################################

use OCBNET::CSS3;
use OCBNET::Image;

use OCBNET::WebSprite::Fit;
use OCBNET::WebSprite::Edge;
use OCBNET::WebSprite::Corner;
use OCBNET::WebSprite::Canvas;
use OCBNET::WebSprite::Sprite;

use OCBNET::CSS3::Styles::Margin;
use OCBNET::CSS3::Styles::Padding;
use OCBNET::CSS3::Styles::Background;
use OCBNET::CSS3::Styles::References;
use OCBNET::CSS3::DOM::Comment::Options;

use OCBNET::CSS3::Regex::Base qw(unwrapUrl wrapUrl);
use OCBNET::CSS3::Regex::Numbers qw(fromPx toPx);
use OCBNET::CSS3::Regex::Background qw(fromPosition);

# load function from core module
use List::MoreUtils qw(uniq);

####################################################################################################
# Constructor - not much going on
####################################################################################################

sub new
{

	# get arguments
	my ($pkg) = @_;

	# create object
	my $obj = {
		# init array
		'sprites' => [],
		# init hash
		'spritesets' => {}
	};

	# bless into package
	bless $obj, $pkg;

}

####################################################################################################
# helper to accept various input sources
# will finally return a css stylesheet object
####################################################################################################

my $parseCSS = sub
{
	# check first if the data is already in desired format
	return $_[0] if UNIVERSAL::isa($_[0], "OCBNET::CSS3::Stylesheet");
	# data was probably a string containing css
	return OCBNET::CSS3::Stylesheet->new->parse($_[0]) unless ref $_[0];
	# data was probably a string reference containing css
	return OCBNET::CSS3::Stylesheet->new->parse(${$_[0]}) if ref $_[0] eq "SCALAR";
	# otherwise we got some invalid data type
	Carp::confess "invalid input data";
};

####################################################################################################
# method to find exactly equal sprite
####################################################################################################

sub findSprite
{

	# get arguments
	my ($self, $config) = @_;

	# disable specific warning
	no warnings 'uninitialized';

	# try all known sprites to find equivalent
	foreach my $sprite (@{$self->{'sprites'}})
	{

		# skip if any of the attributes differ
		next if $sprite->{'filename'} ne $config->{'filename'};
		next if $sprite->{'size-x'} ne $config->{'size-x'};
		next if $sprite->{'size-y'} ne $config->{'size-y'};
		next if $sprite->{'repeat-x'} ne $config->{'repeat-x'};
		next if $sprite->{'repeat-y'} ne $config->{'repeat-y'};
		next if $sprite->{'enclosed-x'} ne $config->{'enclosed-x'};
		next if $sprite->{'enclosed-y'} ne $config->{'enclosed-y'};
		next if $sprite->{'position-x'} ne $config->{'position-x'};
		next if $sprite->{'position-y'} ne $config->{'position-y'};

		# found a sprite
		return $sprite;

	}

	# nothing found
	return undef;

}

####################################################################################################
# method is responsible to write spritesets to the disk
# overload this method if you want to implement it different
####################################################################################################

sub writer
{
	# get input arguments
	my ($self, $path, $data, $opt) = @_;
	# load module optionally
	require File::Slurp;
	# store path to opt if it is an array
	push @{$opt}, $path if ref $opt eq "ARRAY";
	# write the image to the disk (passed data is a scalar ref)
	File::Slurp::write_file $path, { binmode => ':raw' }, $data;
}

####################################################################################################
# method is responsible to read images from the disk
# overload this method if you want to implement it different
####################################################################################################

sub reader
{
	# get input arguments
	my ($self, $path) = @_;
	# load module optionally
	require File::Slurp;
	# read the file from the disk
	File::Slurp::read_file($path, { binmode => ':raw' });
}

####################################################################################################
# main method to create spritesets
####################################################################################################

sub create
{

	# get input arguments
	my ($self, $data, $opt) = @_;

	# convert data to stylesheet
	my $css = &{$parseCSS}($data);

	# put all blocks in a flat array
	my @blocks = ($css, $css->blocks);

	# this will process all and each sub block
	for (my $i = 0; $i < scalar(@blocks); $i ++)
	{ push @blocks, $blocks[$i]->blocks; }

	# remove possible duplicates
	@blocks = uniq @blocks;

	# process to setup canvas
	foreach my $block (@blocks)
	{

		# check if this comment is meant for us
		next unless $block->option('sprite-image');

		# get parsed options collection
		my $options = $block->options;

		# check if this comment is meant for us
		next unless $options->get('sprite-image');

		# check if the sprite image has an associated id
		die "sprite image has no id" unless $options->get('css-id');

		# get the id of this spriteset
		my $id = $block->option('css-id');

		# pass debug mode from config to options
		$options->{'debug'} = $self->{'config'}->{'debug'};

		# create a new canvas object to hold all sprites
		my $canvas = OCBNET::WebSprite::Canvas->new(undef, $options);

		# add canvas to global hash object
		$self->{'spritesets'}->{$id} = $canvas;

		# associate canvas with block
		$block->{'canvas'} = $canvas;

		# store the id for canvas
		$canvas->{'id'} = $id;

	}
	# EO each block

	# filter out all unqiue selectors from each css blocks
	my @selectors = grep { $_->type eq 'selector' } @blocks;

	# now process each selector and setup references
	foreach my $selector (@selectors)
	{
		# find the block where the sprite-image is declared
		# if there is no such block, the selector is not a sprite
		my $block = $selector->find('option', 'sprite-image') || next;
		# check if selector is not a canvas itself and sprite has css-id
		if (! $selector->{'canvas'} && (my $id = $block->option('css-id')))
		{
			# connect the references spriteset to this selector
			$selector->{'canvas'} = $self->{'spritesets'}->{$id};
		}
	}
	# EO each selector

	# now process each selector and setup sprites
	foreach my $selector (@selectors)
	{

		# check if this selector block has a background
		next unless $selector->style('background-image');

		# get associated spriteset canvas
		my $canvas = $selector->{'canvas'} || next;

		# fill sprite config
		my $config = {
			# connect spriteset
			# needed for reader
			'spriteset' => $self,
			# pass debug mode from config
			# will draw funky color backgrounds
			'debug' => $self->{'config'}->{'debug'},
			# get the filename from the url (must be "normalized")
			'filename' => unwrapUrl($selector->style('background-image')),
			# the size the sprite is actually shown in (from css styles)
			'size-x' => fromPx($selector->style('background-size-x')) || undef,
			'size-y' => fromPx($selector->style('background-size-y')) || undef,
			# set repeat options to decide where to ditribute
			'repeat-x' => $selector->style('background-repeat-x') || 0,
			'repeat-y' => $selector->style('background-repeat-y') || 0,
			# set enclosed options to decide where to ditribute
			'enclosed-x' => fromPx($selector->style('width') || 0) || 0,
			'enclosed-y' => fromPx($selector->style('height') || 0) || 0,
			# set position/align options to decide where to ditribute
			'position-x' => fromPosition($selector->style('background-position-x') || 0),
			'position-y' => fromPosition($selector->style('background-position-y') || 0)
		};

		# try to find already loaded sprite
		my $sprite = $self->findSprite($config);

		# or create a new sprite and setup most options
		$sprite = OCBNET::WebSprite::Sprite->new($config) unless $sprite;

		# add sprite to collection
		push @{$self->{'sprites'}}, $sprite;

		# store sprite object on selector
		$selector->{'sprite'} = $sprite;

		# and also store the selector on the sprite
		$sprite->{'selector'} = $selector;

		# add sprite to canvas
		$canvas->add($sprite);

	}
	# EO each selector

	# do the work on every spriteset
	$_->optimize foreach $self->spritesets;
	$_->distribute foreach $self->spritesets;
	$_->finalize foreach $self->spritesets;

	# call write with our file writer
	my $written = $self->write($opt);

	# now process each selector and setup sprites
	foreach my $selector (@selectors)
	{

		# new styles
		my %styles;

		# selector has a canvas, this means the spriteset
		# has been declares within this block, so render it
		# check this directly and not with the object method
		# this way we will really only check the local block
		if ($selector->{'canvas'})
		{

			# get canvas directly from selector block
			# this means that the spriteset was defined
			# inline and not in referenced selector block
			my $canvas = $selector->{'canvas'};

			# get the url of the spriteset image
			my $url = $canvas->{'options'}->get('url');

			# find block that has sprite-image obtion declared
			if (my $block = $selector->find('option', 'sprite-image'))
			{
				# add background image to the selector if
				# sprite-image has been declared on this selector
				# or the sprite-image was declared on the stylesheet
				if ($block eq $selector || $block->isa('Stylesheet'))
				{
					$styles{'background-image'} = wrapUrl($url);
					$styles{'background-repeat'} = 'no-repeat';
				}
			}

			# remove all background styles from selector
			$selector->clean(qr/background(?:\-[a-z0-9])*/);

		};
		# EO each selector

		# check if this selector is configured for a sprite
		if ($selector->{'sprite'})
		{

			# get the sprite for selector
			my $sprite = $selector->{'sprite'};

			# spriteset canvas of block
			my $canvas = $selector->{'canvas'};

			# get the url of the spriteset image
			my $url = $canvas->{'options'}->get('url');

			# get the sprite position within set
			my $offset = $sprite->offset;

			# get position offset vars
			my $offset_x = $offset->{'x'};
			my $offset_y = $offset->{'y'};

			# assertion that the values are defined
			die "no sprite x" unless defined $offset_x;
			die "no sprite y" unless defined $offset_y;

			# get pre-caluculated position in spriteset
			my $spriteset_x = $sprite->{'position-x'};
			my $spriteset_y = $sprite->{'position-y'};

			# assertion that the values are defined
			die "no spriteset x" unless defined $spriteset_x;
			die "no spriteset y" unless defined $spriteset_y;

			# calculate the axes for background size
			my $background_w = toPx($canvas->width / $sprite->scaleX);
			my $background_h = toPx($canvas->height / $sprite->scaleY);

			# align relative to the top and relative to the left
			$spriteset_y = toPx($spriteset_y - ($offset_y + $sprite->paddingTop) / $sprite->scaleY) if $sprite->alignTop;
			$spriteset_x = toPx($spriteset_x - ($offset_x + $sprite->paddingLeft) / $sprite->scaleX) if $sprite->alignLeft;

			# assertion that the actual background position is always a full integer
			warn "spriteset_x is not an integer $spriteset_x" unless $spriteset_x =~ m/^(?:\-?[0-9]+px|top|left|right|bottom)$/i;
			warn "spriteset_y is not an integer $spriteset_y" unless $spriteset_y =~ m/^(?:\-?[0-9]+px|top|left|right|bottom)$/i;

			# check if sprite was distributed
			# if it has no parent it means the
			# sprite has not been included yet
			unless ($sprite->{'parent'})
			{
				# check for debug mode on canvas or sprite
				if ($canvas->{'debug'} || $sprite->{'debug'})
				{
					# make border dark red and background lightly red
					$styles{'border-color'} = 'rgba(96, 0, 0, 0.875)';
					$styles{'background-color'} = 'rgba(255, 0, 0, 0.125)';
				}
			}

			# sprite was distributed
			else
			{

				# add shorthand styles for sprite sizing and position
				$styles{'background-size'} = join(' ', $background_w, $background_h);
				$styles{'background-position'} = join(' ', $spriteset_x, $spriteset_y);

				# add repeating if sprite has it configured
				if ($sprite->isRepeatX && $sprite->isFlexibleX)
				{ $styles{'background-repeat'} = 'repeat-x'; }
				if ($sprite->isRepeatY && $sprite->isFlexibleY)
				{ $styles{'background-repeat'} = 'repeat-y'; }

				# remove all background styles from selector
				$selector->clean(qr/background(?:\-[a-z0-9])*/);

			}

		}
		# EO if has sprite

		# do we have new styles
		if (scalar %styles)
		{

			# render the selector bodies
			my $body = $selector->body;

			# find the first indenting to reuse it
			my $indent = $body =~ m/^([ 	]*)\S/m ? $1 : '	';

			# get the traling whitespace on last line
			my $footer = $body =~ s/([ 	]*)$// ? $1 : '';

			# add some debugger statements into css
			$selector->{'footer'} .= "\n" . $indent . ";/* \\/ added by WebSprite \\/ */\n";

			# add these declarations to the footer to be included within block
			$selector->{'footer'} .= sprintf "%s%s: %s;\n", $indent, $_, $styles{$_} foreach keys %styles;

			# add some debugger statements into css
			$selector->{'footer'} .= $indent . "/* /\\ added by WebSprite /\\ */\n";

			# append traling whitespace again
			$selector->{'footer'} .= $footer;

		}
		# EO if has styles

	}
	# EO each selector

	# css stylesheet
	return $css;

}
# EO create


# write out all spritesets within stylesheet
# ***************************************************************************************
sub write
{

	# get passed arguments
	my ($self, $opt) = @_;

	# status variable
	# info about all writes which is
	# used to optimize files afterwards
	my %written;

	# write all registered spritesets
	foreach my $canvas ($self->spritesets)
	{

		# get name of the canvas
		my $id = $canvas->{'id'};

		# get the css options for canvas
		# they are gathered from block comments
		my $options = $canvas->{'options'};

		# parse sprite image option and add to options for later use
		$options->set('url', unwrapUrl($options->get('sprite-image')));

		# assertion that we have gotten some usefull url to store the image
		die "no sprite image defined for <$id>" unless $options->get('url');

		# call layout on canvas
		$canvas->layout;

		# draw image and check for success
		if (my $image = $canvas->draw)
		{
			# set the output format
			$image->Set(magick => 'png');
			# cal image to binary object
			my $blob = $image->ImageToBlob();
			# get the filename to store image
			my $file = $options->get('url');
			# call method (can be overriden)
			$self->writer($file, $blob, $opt);
		}
		# couldn't draw the image
		else
		{
			# throw a error message, maybe we could
			# extend this a bit to be more verbose
			die "canvas could not be drawn";
		}
		# EO if drawn

	}
	# EO each spriteset

	# return status variable
	return \%written;

}
# EO sub write

####################################################################################################

# return all spritesets in list context
sub spritesets { values %{$_[0]->{'spritesets'}} }

####################################################################################################
####################################################################################################
1;