###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-CSS3 (GPL3)
####################################################################################################
package OCBNET::CSS3::Regex::Background;
####################################################################################################
our $VERSION = '0.2.5';
####################################################################################################

use strict;
use warnings;
our @EXPORT;
our @EXPORT_OK;

####################################################################################################

# load exporter and inherit from it
use Exporter qw(); our @ISA = qw(Exporter);

# define our functions that will be exported
push @EXPORT, qw($re_bg_position fromPosition);
push @EXPORT, qw($re_bg_image $re_bg_attachment $re_bg_repeat);
push @EXPORT, qw($re_bg_positions $re_bg_position_y $re_bg_position_x);

####################################################################################################

use OCBNET::CSS3::Regex::Base;
use OCBNET::CSS3::Regex::Numbers;
use OCBNET::CSS3::Regex::Comments;
use OCBNET::CSS3::Regex::Base qw($re_url);

####################################################################################################

# regular expression for background options
#**************************************************************************************************
our $re_bg_image = qr/(?:none|$re_url|inherit)/i;
our $re_bg_attachment = qr/(?:scroll|fixed|inherit)/i;
our $re_bg_repeat = qr/(?:no-repeat|repeat(?:\-[xy])?)/i;
our $re_bg_position_y = qr/(?:top|bottom|center|$re_length)/i;
our $re_bg_position_x = qr/(?:left|right|center|$re_length)/i;

# regular expression for background position matching
#**************************************************************************************************
our $re_bg_position = qr/(?:left|right|top|bottom|center|$re_length)/i;
our $re_bg_positions = qr/$re_bg_position(?:\s+$re_bg_position)?/i;

####################################################################################################

# parse background position
#**************************************************************************************************
sub fromPosition
{

	# get position string
	my ($position) = @_;

	# default to left/top position
	return 0 unless (defined $position);

	# allow keywords for left and top position
	return 0 if ($position =~ m/^(?:top|left)$/i);

	# return the parsed pixel number if matched
	return $1 if ($position =~ m/^($re_number)(?:px)?$/i);

	# right/bottom are the only valid keywords
	# for the position for most other functions
	return 'right' if ($position =~ m/^right$/i);
	return 'bottom' if ($position =~ m/^bottom$/i);

	# die with a fatal error for invalid positions
	die "unknown background position: <$position>";

}

####################################################################################################
####################################################################################################
1;
