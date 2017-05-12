###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-CSS3 (GPL3)
####################################################################################################
# the font shorthand is one of the most complex ones
# I think I could parse them in any possible order, but
# current browsers seem to ignore the line when font-family
# or font-size are not given. They also must be after any
# other properties (like font-weight). Means they are pretty
# strict (maybe for a good reason) but not too strict anyway.
# This makes it tricky for us to mimic the same behavior here.
# IMO it's not possible to mimic every browser, so we try to
# get pretty close. Otherwise it's up to the css developers to
# write standard compliant code that will be parsed correctly.
####################################################################################################
# tests done with firefox v26.0
# to "understand" a font shorthand:
# both the size and the family must be given
# family must be last, which means that
# size/line-height must be second to last
# no value may contain the keyword inherit
# but the complete value may be set to inherit
# size fallowed by a slash mush have line-height
####################################################################################################
package OCBNET::CSS3::Styles::Font;
####################################################################################################
our $VERSION = '0.2.5';
####################################################################################################

use strict;
use warnings;

####################################################################################################

use OCBNET::CSS3::Regex::Base;
use OCBNET::CSS3::Regex::Colors;
use OCBNET::CSS3::Regex::Numbers;

####################################################################################################
# register longhand properties for fonts
####################################################################################################

OCBNET::CSS3::Styles::register('font-style', qr/(?:normal|italic|oblique)/is, 'normal');
OCBNET::CSS3::Styles::register('font-variant', qr/(?:normal|small-caps)/is, 'normal');
OCBNET::CSS3::Styles::register('font-weight', qr/(?:normal|bold|bolder|lighter|[1-9]00)/is, 'normal');
OCBNET::CSS3::Styles::register('font-size', qr/(?:$re_length|$re_percent|smaller|larger|(?:xx?-)?(?:small|large))/is, 'inherit');
OCBNET::CSS3::Styles::register('line-height', qr/(?:$re_length|$re_percent)/is, 'normal');
OCBNET::CSS3::Styles::register('font-family', qr/(?:$re_string)(?:\s*,\s*$re_string)*/is, 'inherit');

####################################################################################################

# register shorthand property for font
OCBNET::CSS3::Styles::register('font',
{
	# optional styes
	# prefered order
	'prefix' =>
	[
		'font-style',
		'font-variant',
		'font-weight'
	],
	# needed in order
	'ordered' =>
	[
		# always needed
		[ 'font-size' ],
		# next bit is optional, but
		# must have a forward slash
		[
			# attention, logic order here is reversed
			# this way we have the css name always first in the array
			# but this actually means that the regex must match first
			'line-height',
			# value gets mandatory if we find a forwards slash
			qr/\s*\/\s*/
		],
		# always needed
		[ 'font-family' ]
	]
});

####################################################################################################
####################################################################################################
1;
