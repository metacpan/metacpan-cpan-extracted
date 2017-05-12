###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-CSS3 (GPL3)
####################################################################################################
# regular expressions to match css2/css3 selectors
####################################################################################################
package OCBNET::CSS3::Regex::Stylesheet;
####################################################################################################
our $VERSION = '0.2.5';
####################################################################################################

use strict;
use warnings;

####################################################################################################

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter); }

# define our functions that will be exported
BEGIN { our @EXPORT = qw(%opener %closer $re_statement $re_bracket); }

####################################################################################################

use OCBNET::CSS3::Regex::Base;
use OCBNET::CSS3::Regex::Comments;

####################################################################################################

# openers and closers for certain block type
# ***************************************************************************************
our %opener = ( '{' => '{', '[' => '[', '(' => '(', '\"' => '\"', '\'' => '\'' );
our %closer = ( '{' => '}', '[' => ']', '(' => ')', '\"' => '\"', '\'' => '\'' );

# declare regex to parse a block
# with correct bracket counting
# ***************************************************************************************
our $re_bracket; $re_bracket =
qr/
	\{ # match opening bracket
	(?: # inner block capture group
		# match comment after text
		# before has already matched
		(?:(??{$re_comment})|\/)?
		# allowed chars
		[^\\\"\'{}]+ |
		# escaped char
		(?: \\ .)+ |
		# a quoted string
		\' (??{$re_apo}) \' |
		\" (??{$re_quot}) \" |
		# recursive blocks
		(??{$re_bracket})
	)* # can be empty or repeat
	\} # match closing bracket
/xs;

# declare regex to parse a rule
# optional brackets (ie. media query)
# ***************************************************************************************
our $re_statement; $re_statement =
qr/
	(?:
		# match single comments, or
		(\s*(??{$re_comment})\s*) |
		# .. capture complex text
		((?:
			# match comment after text
			# before has already matched
			(?:(??{$re_comment})|\/)?
			# capture any text
			(?:
				# allowed chars
				[^\\\"\'\/{};]+ |
				# escaped char
				(?: \\ .)+ |
				# a quoted string
				\' (??{$re_apo}) \' |
				\" (??{$re_quot}) \" |
			)
		# can repeat
		)+)
		# get optional scope
		((??{$re_bracket})?)
	)
	# exit clause
	( (?:\z|;+)? )
/xs;

####################################################################################################
####################################################################################################
1;
