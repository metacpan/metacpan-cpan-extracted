###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-CSS3 (GPL3)
####################################################################################################
# regular expressions to match css2/css3 selectors
####################################################################################################
package OCBNET::CSS3::Regex::Selectors;
####################################################################################################
our $VERSION = '0.2.5';
####################################################################################################

use strict;
use warnings;

####################################################################################################

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter); }

# define our functions that will be exported
BEGIN { our @EXPORT = qw($re_selector_rules); }

# define our functions than can be exported
BEGIN { our @EXPORT_OK = qw($re_selector_rule $re_options); }

####################################################################################################

use OCBNET::CSS3::Regex::Base;

####################################################################################################

# create matchers for the various css selector types
our $re_id = qr/\#$re_identifier/; # select single id
our $re_tag = qr/(?:$re_identifier|\*)/; # select single tag
our $re_class = qr/\.$re_identifier/; # select single class
our $re_pseudo = qr/\:{1,2}$re_identifier/; # select single pseudo

####################################################################################################

# select attributes and values
# advanced css2/css3 selectors
our $re_attr = qr/
	# open attribute
	\[
		# fetch a name
		$re_identifier
		\s*
		(?:
			# operator prefix
			[\~\^\$\*\|]?
			# the equal sign
			\s* = \s*
			# find value
			(?:
				# quoted string
				  \' $re_apo \'
				| \" $re_quot \"
				  # escape char sequence
				| (?: [^\)\\]+ | \\. )*
			)
			# has value
		)?
	# close attribute
	\]
/x;

####################################################################################################

# create expression to match a single rule
# example : DIV#id.class1.class2:hover
our $re_selector = qr/(?:
	  \*
	| $re_attr* $re_pseudo+
	| $re_class+ $re_attr* $re_pseudo*
	| $re_id $re_class* $re_attr* $re_pseudo*
	| $re_tag $re_id? $re_class* $re_attr* $re_pseudo*
)/x;

####################################################################################################

# create expression to match complex rules
# example : #id DIV.class FORM A:hover
our $re_selector_rule = qr/$re_selector(?:(?:\s*[\>\+\~]\s*|\s+)$re_selector)*/;

####################################################################################################

# create expression to match multiple complex rules
# example : #id DIV.class FORM A:hover, BODY DIV.header
our $re_selector_rules = qr/$re_selector_rule(?:\s*,\s*$re_selector_rule)*/;

####################################################################################################
####################################################################################################
1;
