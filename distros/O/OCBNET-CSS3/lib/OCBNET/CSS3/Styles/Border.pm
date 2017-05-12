###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-CSS3 (GPL3)
####################################################################################################
package OCBNET::CSS3::Styles::Margin;
####################################################################################################
our $VERSION = '0.2.5';
####################################################################################################

use strict;
use warnings;

####################################################################################################
# import regular expressions
####################################################################################################

use OCBNET::CSS3::Regex::Colors;
use OCBNET::CSS3::Regex::Numbers;

####################################################################################################
# define local regular expression for borders
####################################################################################################

# regular expression to match border style (without inherit keyword)
#**************************************************************************************************
my $re_border_style = qr/(?:none|hidden|dotted|dashed|solid|double|groove|ridge|inset|outset)/si;

####################################################################################################
# register longhand properties for border
####################################################################################################

# register longhand properties for border widths
#**************************************************************************************************
OCBNET::CSS3::Styles::register('border-top-width', $re_length, '0');
OCBNET::CSS3::Styles::register('border-left-width', $re_length, '0');
OCBNET::CSS3::Styles::register('border-right-width', $re_length, '0');
OCBNET::CSS3::Styles::register('border-bottom-width', $re_length, '0');

# register longhand properties for border colors
#**************************************************************************************************
OCBNET::CSS3::Styles::register('border-top-color', $re_color, 'transparent');
OCBNET::CSS3::Styles::register('border-left-color', $re_color, 'transparent');
OCBNET::CSS3::Styles::register('border-right-color', $re_color, 'transparent');
OCBNET::CSS3::Styles::register('border-bottom-color', $re_color, 'transparent');

# register longhand properties for border styles
#**************************************************************************************************
OCBNET::CSS3::Styles::register('border-top-style', $re_border_style, 'none');
OCBNET::CSS3::Styles::register('border-left-style', $re_border_style, 'none');
OCBNET::CSS3::Styles::register('border-right-style', $re_border_style, 'none');
OCBNET::CSS3::Styles::register('border-bottom-style', $re_border_style, 'none');

####################################################################################################
# register shorthand properties for border
####################################################################################################

# register shorthand property for border-width
#**************************************************************************************************
OCBNET::CSS3::Styles::register('border-width',
{
	# needed in order
	'ordered' =>
	[
		# always needed
		[ 'border-top-width' ],
		# additional optional values
		# may evaluate to other value
		[ 'border-right-width', 'border-top-width'],
		[ 'border-bottom-width', 'border-top-width'],
		[ 'border-left-width', 'border-right-width']
	],
	# needed for own shorthand
	'matcher' => $re_length
},
# default
'0');

# register shorthand property for border-color
#**************************************************************************************************
OCBNET::CSS3::Styles::register('border-color',
{
	# needed in order
	'ordered' =>
	[
		# always needed
		[ 'border-top-color' ],
		# additional optional values
		# may evaluate to other value
		[ 'border-right-color', 'border-top-color'],
		[ 'border-bottom-color', 'border-top-color'],
		[ 'border-left-color', 'border-right-color']
	],
	# needed for own shorthand
	'matcher' => $re_color
},
# default
'transparent');

# register shorthand property for border-style
#**************************************************************************************************
OCBNET::CSS3::Styles::register('border-style',
{
	# needed in order
	'ordered' =>
	[
		# always needed
		[ 'border-top-style' ],
		# additional optional values
		# may evaluate to other value
		[ 'border-right-style', 'border-top-style'],
		[ 'border-bottom-style', 'border-top-style'],
		[ 'border-left-style', 'border-right-style']
	],
	# needed for own shorthand
	'matcher' => $re_border_style
},
# default
'none');

####################################################################################################

# register shorthand property for border
#**************************************************************************************************
OCBNET::CSS3::Styles::register('border',
{
	# random order
	'prefix' =>
	[
		'border-width',
		'border-style',
		'border-color'
	]
});

####################################################################################################
####################################################################################################
1;
