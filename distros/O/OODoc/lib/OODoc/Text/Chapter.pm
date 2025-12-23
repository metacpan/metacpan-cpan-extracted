# This code is part of Perl distribution OODoc version 3.05.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package OODoc::Text::Chapter;{
our $VERSION = '3.05';
}

use parent 'OODoc::Text::Structure';

use strict;
use warnings;

use Log::Report    'oodoc';

use List::Util     qw/first/;

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$args->{type}       ||= 'Chapter';
	$args->{container}  ||= delete $args->{manual} or panic;
	$args->{level}      ||= 1;
	$self->SUPER::init($args) or return;
	$self->{OTC_sections} = [];
	$self;
}

sub emptyExtension($)
{	my ($self, $container) = @_;
	my $empty = $self->SUPER::emptyExtension($container);
	my @sections = map $_->emptyExtension($empty), $self->sections;
	$empty->sections(@sections);
	$empty;
}

sub manual() { $_[0]->container }
sub path()   { $_[0]->name }

sub findSubroutine($)
{	my ($self, $name) = @_;
	my $sub = $self->SUPER::findSubroutine($name);
	return $sub if defined $sub;

	foreach my $section ($self->sections)
	{	my $sub = $section->findSubroutine($name);
		return $sub if defined $sub;
	}

	undef;
}

sub findEntry($)
{	my ($self, $name) = @_;
	return $self if $self->name eq $name;

	foreach my $section ($self->sections)
	{	my $entry = $section->findEntry($name);
		return $entry if defined $entry;
	}

	();
}

sub all($@)
{	my $self = shift;
	  (	$self->SUPER::all(@_),
		(map $_->all(@_), $self->sections),
	  );
}

#--------------------

sub section($)
{	my ($self, $thing) = @_;

	if(ref $thing)
	{	push @{$self->{OTC_sections}}, $thing;
		return $thing;
	}

	first { $_->name eq $thing } $self->sections;
}


sub sections()
{	my $self = shift;
	if(@_)
	{	$self->{OTC_sections} = [ @_ ];
		$_->container($self) for @_;
	}
	@{$self->{OTC_sections}};
}

*nest = \*sections;

1;
