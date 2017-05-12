###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-CSS3 (GPL3)
####################################################################################################
package OCBNET::CSS3::Property::Background;
####################################################################################################
our $VERSION = '0.2.5';
####################################################################################################

use strict;
use warnings;

####################################################################################################

use OCBNET::CSS3::Regex::Colors;
use OCBNET::CSS3::Regex::Background;
use OCBNET::CSS3::Regex::Numbers qw($re_length);

####################################################################################################
# register longhand properties for backgrounds
####################################################################################################

OCBNET::CSS3::Styles::register('background-color', $re_color, 'transparent', 1);
OCBNET::CSS3::Styles::register('background-image', $re_bg_image, 'none', 1);
OCBNET::CSS3::Styles::register('background-repeat', $re_bg_repeat, 'repeat', 1);
OCBNET::CSS3::Styles::register('background-size-x', $re_length, undef, 1);
OCBNET::CSS3::Styles::register('background-size-y', $re_length, undef, 1);
OCBNET::CSS3::Styles::register('background-position-y', $re_bg_position_y, 'top', 1);
OCBNET::CSS3::Styles::register('background-position-x', $re_bg_position_x, 'left', 1);
OCBNET::CSS3::Styles::register('background-attachment', $re_bg_attachment, 'scroll', 1);

####################################################################################################
# register shorthand property for background-size
####################################################################################################

OCBNET::CSS3::Styles::register('background-size',
{
	'ordered' => [
		# always needed
		[ 'background-size-x' ],
		# additional optional values
		# may evaluate to other value
		[ 'background-size-y', 'background-size-x' ]
	],
}, undef, 1);

####################################################################################################
# register shorthand property for background-position
####################################################################################################

OCBNET::CSS3::Styles::register('background-position',
{
	'prefix' => [
		'background-position-x',
		'background-position-y'
	],
	'matcher' => $re_bg_positions
}, 'top left', 1);

####################################################################################################
# register shorthand property for background
####################################################################################################
OCBNET::CSS3::Styles::register('background',
{
	'prefix' => [
		'background-color',
		'background-image',
		'background-repeat',
		'background-attachment',
		'background-position'
	]
}, 'none', 1);

####################################################################################################
# register getters for virtual longhand properties
####################################################################################################

OCBNET::CSS3::Styles::getter('background-repeat-x', sub
{
	my ($self, $type, $name, $idx) = @_;
	my $repeat = $self->get($type, 'background-repeat', $idx) || return 1;
	return $repeat eq "repeat-x" || $repeat eq "repeat" ? 'repeat' : 0;
});

OCBNET::CSS3::Styles::getter('background-repeat-y', sub
{
	my ($self, $type, $name, $idx) = @_;
	my $repeat = $self->get($type, 'background-repeat', $idx) || return 1;
	return $repeat eq "repeat-y" || $repeat eq "repeat" ? 'repeat' : 0;
});

####################################################################################################
####################################################################################################
1;
