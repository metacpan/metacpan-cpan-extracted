###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-CSS3 (GPL3)
####################################################################################################
package OCBNET::CSS3::DOM::Property;
####################################################################################################
our $VERSION = '0.2.5';
####################################################################################################

use strict;
use warnings;

####################################################################################################
use base 'OCBNET::CSS3';
use Scalar::Util 'blessed';
####################################################################################################

use OCBNET::CSS3::Regex::Comments;

####################################################################################################

# static getter
#**************************************************************************************************
sub type { return 'property' }

# advanced getters
#**************************************************************************************************
sub key { uncomment $_[0]->{'key'} }
sub value { uncomment $_[0]->{'value'} }
sub comment { comments $_[0]->{'value'} }

####################################################################################################

# set the readed text
# parse key and value
sub set
{

	# get input arguments
	my ($self, $text) = @_;

	# call super class method
	$self->SUPER::set($text);

	# split the key and the value
	# leave whitespace to save later
	my ($key, $value) = split(':', $text, 2);

	# remove whitespace
	my $whitespace =
	{
		'key-prefix' => $key =~ s/\A((?:\s+|$re_comment)+)//s ? $1 : '',
		'key-postfix' => $key =~ s/\A((?:\s+|$re_comment)+)//s ? $1 : '',
		'value-prefix' => $value =~ s/((?:\s+|$re_comment)+)\z//s ? $1 : '',
		'value-postfix' => $value =~ s/((?:\s+|$re_comment)+)\z//s ? $1 : '',
	};

	# store whitespace for rendering
	$self->{'whitespace'} = $whitespace;

	# store key and value
	# as parsed (with comments)
	$self->{'key'} = $key;
	$self->{'value'} = $value;

	# only parse if parent is a valid block
	if ($self->parent && $self->parent->styles)
	{
		# uncomment key/value pair
		$key = $self->key; $value = $self->value;
		# parse key/value pairs into parent styles
		$self->parent->styles->set($key, $value);
	}

	# instance
	return $self;

}
# EO sub set

####################################################################################################

sub render
{

	# get input arguments
	my ($self, $comments, $indent) = @_;

	# declare string
	my $code = '';

	# init default indent
	$indent = 0 unless $indent;

	# print to debug the css "dom" tree
	# print "  " x $indent, $self, "\n";

	# put back the original code
	$code .= $self->{'whitespace'}->{'key-prefix'};
	$code .= $self->{'key'};
	$code .= $self->{'whitespace'}->{'key-postfix'};
	$code .= ':';
	$code .= $self->{'whitespace'}->{'value-prefix'};
	$code .= $self->{'value'};
	$code .= $self->{'whitespace'}->{'value-postfix'};

	# re-add suffix if one has been parsed
	$code .= $self->suffix if $self->suffix;

	# return code
	return $code;

}
# EO sub render

####################################################################################################

# load regex for vendor prefixes
#**************************************************************************************************
use OCBNET::CSS3::Regex::Base qw($re_identifier);

# add basic extended type with highest priority
#**************************************************************************************************
unshift @OCBNET::CSS3::types, [
	qr/\A\s*$re_identifier\s*\:/is,
	'OCBNET::CSS3::DOM::Property',
	sub { ! $_[1] }
];

####################################################################################################
####################################################################################################
1;
