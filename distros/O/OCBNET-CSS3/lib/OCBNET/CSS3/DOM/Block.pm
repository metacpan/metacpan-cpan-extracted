###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-CSS3 (GPL3)
####################################################################################################
# a css3 object with styles and options
####################################################################################################
package OCBNET::CSS3::DOM::Block;
####################################################################################################
our $VERSION = '0.2.5';
####################################################################################################

use strict;
use warnings;

####################################################################################################
use base 'OCBNET::CSS3';
use OCBNET::CSS3::Styles;
####################################################################################################

# create a new object
# ***************************************************************************************
sub new
{

	# package name
	my ($pckg) = shift;

	# create a new instance
	my $self = $pckg->SUPER::new;

	# store only longhands
	$self->{'style'} = OCBNET::CSS3::Styles->new($self);
	$self->{'option'} = OCBNET::CSS3::Styles->new($self);

	# instance
	return $self;

}
# EO constructor

####################################################################################################

# static getter
# always overwrite this
#**************************************************************************************************
sub type { die 'not implemented' }

# static getters
#**************************************************************************************************
sub styles { $_[0]->{'style'} }
sub options { $_[0]->{'option'} }

####################################################################################################

# getter with recursive logic
# can reference ids in options
# try to load styles from there
#**************************************************************************************************
sub get
{

	# get input arguments
	my ($self, $type, $key, $idx) = @_;

	# try to get/call registered getter function for key
	my $getter = $OCBNET::CSS3::Styles::getter{$key};
	return $getter->($self, $type, $key, $idx) if defined $getter;

	# check if found in current styles
	if (exists $self->{$type}->{$key}->[$idx || 0])
	{ return $self->{$type}->{$key}->[$idx || 0]; }

	# do not go recursive on certain keys
	return undef if $key eq 'css-ref';
	return undef if $key eq 'css-id';

	# find the node that has the key
	my $node = $self->find($type, $key);

	# return if nothing found
	return undef unless $node;

	# return results from getter
	$node->get($type, $key, $idx);

}
# EO sub get

####################################################################################################

# getters for styles and options
#**************************************************************************************************
sub style { get(shift, 'style', @_) }
sub option { get(shift, 'option', @_) }

####################################################################################################

# getter with recursive logic
# can reference ids in options
# try to load options from there
#**************************************************************************************************
sub find
{

	# get input arguments
	my ($self, $type, $key) = @_;

	# check if found in current styles
	if (exists $self->{$type}->{$key})
	{ return $self if scalar(@{$self->{$type}->{$key}}) }

	# do not go recursive on certain keys
	# return undef if $key eq 'css-ref';
	# return undef if $key eq 'css-id';

	# check each css references for given key
	foreach my $id ($self->options->list('css-ref'))
	{
		# get the actual referenced dom node
		my $ref = $self->root->{'ids'}->{$id};
		# give error message if reference was not found
		die "referenced id <$id> not found" unless $ref;
		# resolve value on referenced block
		# will itself try to resolve further
		my $result = $ref->find($type, $key);
		# only return if result is defined
		return $result if defined $result;
	}

	# nothing found
	return undef;

}
# EO sub option

####################################################################################################

# helper to check if we implement a certain class
#**************************************************************************************************
sub isa {  shift->SUPER::isa(map { 'OCBNET::CSS3::' . $_ } @_) }

####################################################################################################

# remove certain styles
#**************************************************************************************************
sub clean
{

	# get selector and regex
	# remove styles found by regex
	my ($selector, $regexp) = @_;

	# define default expression to clean all
	$regexp = qr// unless defined $regexp;

	# remove options
	foreach my $key (keys %{$selector->{'option'}})
	{
		next unless $key =~ m/^\s*$regexp/is;
		delete $selector->{'option'}->{$key};
	}

	# remove styles
	foreach my $key (keys %{$selector->{'style'}})
	{
		next unless $key =~ m/^\s*$regexp/is;
		delete $selector->{'style'}->{$key};
	}

	# define default expression to clean all
	$regexp = qr// unless defined $regexp;

	# remove all background declarations now
	@{$selector->{'children'}} = grep {
		not ($_->{'key'} && $_->{'key'} =~ m/^\s*$regexp/is)
	} @{$selector->{'children'}};


}
# EO sub clean

####################################################################################################
####################################################################################################
1;
