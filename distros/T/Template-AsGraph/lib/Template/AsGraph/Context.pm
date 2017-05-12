#============================================================= -*-Perl-*-
#
# Template::AsGraph::Context
#
# DESCRIPTION
#   Wrapper module for original Template::Context, populating a tree
#   structure for each processed template.
#
# AUTHOR
#   Breno G. de Oliveira   <garu@cpan.org>
#
# COPYRIGHT
#   Copyright (C) 2009 Breno G. de Oliveira.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
# 
#============================================================================

package Template::AsGraph::Context;
# maybe this should be refactored into a separate
# module such as TemplateX::Context::Routes

use strict;
use warnings;
use base 'Template::Context';

our $VERSION = '0.01';

#TODO: make tree-building code suck less
# preferably getting rid of this:
our $_tree = {};


#------------------------------------------------------------------------
# process($template, \%params)         [% PROCESS template var=val ... %]
# process($template, \%params, $local) [% INCLUDE template var=val ... %]
#
# This is a wrapper for Template::Context's process() method. It creates
# a tree of visited templates as it goes deeper into them.
# 
# The tree hash can be accessed after process() is called via
# $template->context->tree
#------------------------------------------------------------------------

sub process {
	my ($self, $template, $params, $localize) = @_;
	
	# find out the name of the template
	my $name = ref($template) eq 'ARRAY'
	         ? join (' + ', @{$template}) : ref($template)
	         ? $template->name            : $template
	         ;

	# initialize tree node
	$_tree->{$name} = {};

	# prepare environment and call parent's
	# original process() method. This will recursively
	# come back here with a localized version of the
	# tree so we can place our node with the command
	# above.
	my $output;
	{
		local $_tree = $_tree->{$name};
		$output = $self->SUPER::process($template, $params, $localize);
	}
	
	# this will make our parent automatically create
	# the $context->tree() method with our entire
	# template tree.
	$self->{ TREE } = $_tree;
	
	# finally, return the output just like
	# the original process() does.
	return $output;
}

42;