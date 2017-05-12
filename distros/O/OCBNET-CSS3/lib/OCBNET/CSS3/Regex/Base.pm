###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-CSS3 (GPL3)
####################################################################################################
package OCBNET::CSS3::Regex::Base;
####################################################################################################
our $VERSION = '0.2.7';
####################################################################################################

use strict;
use warnings;
our @EXPORT;
our @EXPORT_OK;

####################################################################################################

# load exporter and inherit from it
use Exporter qw(); our @ISA = qw(Exporter);

# define our functions that will be exported
push @EXPORT, qw($re_apo $re_quot $re_identifier $re_string);
push @EXPORT_OK, qw($re_uri $re_import last_match last_index);
push @EXPORT_OK, qw($re_vendors $re_url unquot unwrapUrl wrapUrl);

####################################################################################################
# base regular expressions
####################################################################################################

# match text in apos or quotes
#**************************************************************************************************
our $re_apo = qr/(?:[^\'\\]+|\\.)*/s;
our $re_quot = qr/(?:[^\"\\]+|\\.)*/s;

# match an identifier or name
#**************************************************************************************************
our $re_identifier = qr/\b[_a-zA-Z][_a-zA-Z0-9\-]*/s;

# match a text (can be identifier or quoted string)
#**************************************************************************************************
our $re_string = qr/(?:$re_identifier|\"$re_quot\"|\'$re_apo\')/is;

# regular expression to match a wrapped url
#**************************************************************************************************
our $re_url = qr/url\((?:\'$re_apo\'|\"$re_quot\"|[^\)]*)\)/s;

# match vendors prefixes
#**************************************************************************************************
our $re_vendors = qr/(?:o|ms|moz|webkit)/is;

####################################################################################################

# parse urls out of the css file
# only supports wrapped urls
our $re_uri = qr/url\(\s*(?:
	\s*\"(?!data:)($re_quot)\" |
	\s*\'(?!data:)($re_apo)\' |
	(?![\"\'])\s*(?!data:)([^\)]*)
)\s*\)/xi;

####################################################################################################

# parse urls out of the css file
# also supports not wrapped urls
our $re_import = qr/\@import\s*(?:
	url\(\s*(?:
		\s*\"(?!data:)($re_quot)\" |
		\s*\'(?!data:)($re_apo)\' |
		(?![\"\'])\s*(?!data:)([^\)]*)
	)\) | (?:
		\s*\"(?!data:)($re_quot)\" |
		\s*\'(?!data:)($re_apo)\' |
		(?![\"\'])\s*(?!data:)([^\s;]*)
	))
\s*;?/xi;

####################################################################################################
# regular expressions helpers
####################################################################################################

# return first defined match of last expression
# helper for expressions that match alternatives
sub last_match ()
{
	if (defined $1) { $1 }
	elsif (defined $2) { $2 }
	elsif (defined $3) { $3 }
	elsif (defined $4) { $4 }
	elsif (defined $5) { $5 }
	elsif (defined $6) { $6 }
	elsif (defined $7) { $7 }
	elsif (defined $8) { $8 }
	elsif (defined $9) { $9 }
}

# return index of first defined match of last expression
# can be used to differentiate between match alternatives
sub last_index ()
{
	if (defined $1) { 1 }
	elsif (defined $2) { 2 }
	elsif (defined $3) { 3 }
	elsif (defined $4) { 4 }
	elsif (defined $5) { 5 }
	elsif (defined $6) { 6 }
	elsif (defined $7) { 7 }
	elsif (defined $8) { 8 }
	elsif (defined $9) { 9 }
}

####################################################################################################

# a very plain and simply unquote function
# implement correctly once we actually find the specs
# although we could add some known escaping sequences
#**************************************************************************************************
sub unquot
{
	# get the string
	my $txt = $_[0];
	# replace hexadecimal representation
	# http://www.w3.org/International/questions/qa-escapes
	$txt =~ s/\\([0-9A-F]{2,6})\s?/chr hex $1/eg;
	$txt =~ s/\&\#x([0-9A-F]{2,6});\s?/chr hex $1/eg;
	$txt =~ s/\&\#([0-9]{2,6});\s?/chr $1/eg;
	# replace escape character
	$txt =~ s/\\(.)/$1/g;
	# return result
	$txt;
}

####################################################################################################

# unwrap an url
#**************************************************************************************************
sub unwrapUrl
{
	# check for css url pattern (call again to unwrap quotes)
	return unwrapUrl($1) if $_[0] =~ m/\A\s*url\(\s*(.*?)\s*\)\s*\z/m;
	# unwrap quotes if there are any
	return $1 if $_[0] =~ m/\A\"(.*?)\"\z/m;
	return $1 if $_[0] =~ m/\A\'(.*?)\'\z/m;
	# return same as given
	return $_[0];
}

# wrap an url
#**************************************************************************************************
sub wrapUrl
{
	# get url from arguments
	my $url = $_[0];
	# change slashes
	$url =~ s/\\/\//g;
	# escape quotes
	$url =~ s/\"/\\\"/g;
	# return wrapped url
	return 'url("' . $url . '")';
}

####################################################################################################
####################################################################################################
1;
