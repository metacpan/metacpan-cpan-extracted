###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-CSS3 (GPL3)
####################################################################################################
package OCBNET::CSS3::Regex::Numbers;
####################################################################################################
our $VERSION = '0.2.5';
####################################################################################################

use strict;
use warnings;

####################################################################################################

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter); }

# define our functions that will be exported
BEGIN { our @EXPORT = qw($re_number $re_percent $re_size $re_length $re_byte fromPx toPx); }

####################################################################################################
# base regular expressions
####################################################################################################

# match (floating point) numbers
#**************************************************************************************************
our $re_number = qr/[\-\+]?[0-9]*\.?[0-9]+/s;
# our $re_number_neg = qr/\-[0-9]*\.?[0-9]+/s;
# our $re_number_pos = qr/\+?[0-9]*\.?[0-9]+/s;

# regular expression to match a percent property
#**************************************************************************************************
our $re_percent = qr/$re_number(?:\%)/i;

# regular expression to match a size property
#**************************************************************************************************
our $re_size = qr/$re_number(?:em|ex|px|in|cm|mm|pt|pc)/i;

# regular expression to match any length property
#**************************************************************************************************
our $re_length = qr/$re_number(?:em|ex|px|\%|in|cm|mm|pt|pc)?/i;

# match a octal number from 0 to 255 (strict match)
#**************************************************************************************************
our $re_byte = qr/(?:0|[1-9]\d?|1\d{2}|2(?:[0-4]\d|5[0-5]))/s;

####################################################################################################

# parse dimension from pixel
#**************************************************************************************************
sub fromPx
{
	# return undef if nothing passed
	return unless defined $_[0];
	# parse number via regular expression (pretty strict)
	$_[0] =~ m/\A\s*($re_number)(?:px)?\s*\z/i ? $1 : undef;
}

# adds pixel unit
#**************************************************************************************************
sub toPx
{
	# parse via fromPx
	my $px = fromPx($_[0]);
	# check if input was valid
	return undef unless defined $px;
	# format correctly
	sprintf "%gpx", $px
}

####################################################################################################
####################################################################################################
1;
