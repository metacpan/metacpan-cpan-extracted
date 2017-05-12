###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-CSS3 (GPL3)
####################################################################################################
package OCBNET::CSS3;
####################################################################################################
our $VERSION = '0.2.7';
####################################################################################################

use strict;
use warnings;

####################################################################################################

our @types;

####################################################################################################

# load other base classes
use OCBNET::CSS3::Stylesheet;
use OCBNET::CSS3::DOM::Block;
# load different types
use OCBNET::CSS3::DOM::Comment;
use OCBNET::CSS3::DOM::Extended;
use OCBNET::CSS3::DOM::Selector;
use OCBNET::CSS3::DOM::Property;
use OCBNET::CSS3::DOM::Whitespace;
# text is the last order
use OCBNET::CSS3::DOM::Text;

####################################################################################################

# load regular expressions
use OCBNET::CSS3::Regex::Base;
use OCBNET::CSS3::Regex::Colors;
use OCBNET::CSS3::Regex::Numbers;
use OCBNET::CSS3::Regex::Comments;
use OCBNET::CSS3::Regex::Selectors;
use OCBNET::CSS3::Regex::Stylesheet;

####################################################################################################
# is common base for all classes
####################################################################################################

# create a new object
# ***************************************************************************************
sub new
{

	# package name
	my ($pckg) = shift;

	# create a new instance
	my $self = {

		'ids' => {},
		'text' => undef,
		'footer' => '',
		'suffix' => undef,
		'bracket' => undef,
		'children' => [],

	};

	# bless instance into package
	return bless $self, $pckg;

}
# EO constructor

####################################################################################################

# get statistics object
# ***************************************************************************************
sub stats
{

	my ($node) = @_;

	# add first object
	my @objects = ($node);

	# array to count items
	my (@imports, @selectors);

	# process as long as we have objects
	while (my $object = shift @objects)
	{
		# process children array
		if ($object->{'children'})
		{
			# add object to counter arrays
			push @objects, @{$object->{'children'}};
			push @imports, $object if $object->type eq 'import';
			push @selectors, $object if $object->type eq 'selector';
		}
	}

	# split imports and selectors by commas
	@imports = map { split /,/, $_->text } @imports;
	@selectors = map { split /,/, $_->text } @selectors;

	# KB 262161 outlines the maximum number of stylesheets
	# and rules supported by Internet Explorer 6 to 9.
	# - A sheet may contain up to 4095 rules
	# - A sheet may @import up to 31 sheets
	# - @import nesting supports up to 4 levels deep

	return { 'imports' => \@imports, 'selectors' => \@selectors }

}
# EO stats

####################################################################################################

# create a cloned object
# ***************************************************************************************
sub clone
{

	# get passed arguments
	my ($self, $deep) = @_;

	# create an empty cloned object
	my $clone = ref($self)->new;

	# clone all basic values
	$clone->set($self->text);
	$clone->suffix = $self->suffix;
	$clone->bracket = $self->bracket;

	# return now if deep no set
	return $clone unless $deep;

	# add a clone of each child to clone
	foreach my $child (@{$self->children})
	{ $clone->add($child->clone($deep)) }

	# new instance
	return $clone;

}
# EO sub clone

####################################################################################################

# static getter (overwrite)
# ***************************************************************************************
sub type { return 'base' }

# main setter method
# overwrite to parse object
# ***************************************************************************************
sub set { $_[0]->text = $_[1] }

# setter and getter
# ***************************************************************************************
sub text : lvalue { $_[0]->{'text'} }
sub suffix : lvalue { $_[0]->{'suffix'} }
sub bracket : lvalue { $_[0]->{'bracket'} }

# getter (set via reference)
# ***************************************************************************************
sub parent { $_[0]->{'parent'} }
sub children { $_[0]->{'children'} }

# get only css block scopes
# ***************************************************************************************
sub blocks { grep { UNIVERSAL::isa($_, 'OCBNET::CSS3::DOM::Block') } @{$_[0]->children} }

# get typed blocks in list context
# ***************************************************************************************
sub imports { grep { $_->type eq 'import' } $_[0]->blocks }
sub selectors { grep { $_->type eq 'selector' } $_[0]->blocks }

# get child by index
# ***************************************************************************************
sub child { $_[0]->{'children'}->[ $_[1] ] }

# get the root node (the one without parent)
# ***************************************************************************************
sub root { $_[0]->parent ? $_[0]->parent->root : $_[0] }

####################################################################################################

# parse given text
# attachs new objects
sub parse
{

	# get input arguments
	my ($self, $text) = @_;

	# maybe we should error out here
	return $self unless defined $text;

	# parse as much as possible
	# a stricter version would replace the parsed
	# code and check the final string to be empty
	while ($text =~ s/\A$re_statement//s)
	# while ($text =~ m/$re_statement/g)
	{
		# declare object
		my $object;

		# store the different parts from the match
		my $match = defined $1 ? $1 : $2;
		my ($scope, $suffix) = ($3, $4);

		# copy uncommented text
		my $code = uncomment $match;

		# dynamically find type
		foreach my $type (@types)
		{
			# get options from type array
			my ($regex, $pckg, $tst) = @{$type};
			# skip if type does not match
			next unless $code =~ m/$regex/s;
			# call optional test if one is defined
			next if $tst && ! $tst->($match, $scope);
			# create new dynamic object
			$object = $pckg->new; last;
		}
		# EO each type

		# create object if no other type found
		$object = new OCBNET::CSS3 unless $object;

		# add object to scope
		$self->add($object);

		# set the main text
		$object->set($match);

		# set to the parsed suffix
		$object->suffix = $suffix;

		# set scope status if we have parsed one
		$object->bracket = $scope ? '{' : undef;

		# remove block brackets from scope
		$scope = substr($scope, 1, -1) if $scope;

		# parse scope (only if scope was found)
		$object->parse($scope) if $object->bracket;

		# check exit clause
		last if $text eq '';

	}
	# EO each statement

	# assert that everything was parsed
	die "parse error" unless $text eq '';

	# instance
	return $self;

}
# EO sub parse

####################################################################################################

# add some children
# ***************************************************************************************
sub add
{

	# get input arguments
	my ($self, @children) = @_;

	# add passed children to our array
	push @{$self->{'children'}}, @children;

	# attach us as parent to all children
	$_->{'parent'} = $self foreach @children;

	# instance
	return $self;

}
# EO sub add

# prepend some children
# ***************************************************************************************
sub prepend
{

	# get input arguments
	my ($self, @children) = @_;

	# add passed children to our array
	unshift @{$self->{'children'}}, @children;

	# attach us as parent to all children
	$_->{'parent'} = $self foreach @children;

	# instance
	return $self;

}
# EO sub prepend

####################################################################################################

sub body
{
	# get input arguments
	my ($self, $comments, $indent) = @_;

	# declare string
	my $code = '';

	# init default indent
	$indent = 0 unless $indent;

	# render and add each children
	foreach my $child (@{$self->children})
	{ $code .= $child->render($comments, $indent + 1); }

	# return result
	return $code;

}

# render block with children
# return the same css as parsed
# ***************************************************************************************
sub render
{

	# get input arguments
	my ($self, $comments, $indent) = @_;

	# declare string
	my $code = '';

	# init default indent
	$indent = 0 unless $indent;

	# add code from instance
	if (defined $self->text)
	{ $code .= $self->text; }

	# print to debug the css "dom" tree
	# print "  " x $indent, $self, "\n";

	# add opener bracket if scope has been set
	$code .= $opener{$self->bracket} if $self->bracket;

	# render and add each children
	foreach my $child (@{$self->children})
	{ $code .= $child->render($comments, $indent + 1); }

	# append some generic footer
	$code .= $self->{'footer'};

	# add closer bracket if scope has been set
	$code .= $closer{$self->bracket} if $self->bracket;

	# add object suffix if it has been set
	$code .= $self->suffix if defined $self->suffix;

	# return string
	return $code;

}
# EO sub render

####################################################################################################
####################################################################################################
1;