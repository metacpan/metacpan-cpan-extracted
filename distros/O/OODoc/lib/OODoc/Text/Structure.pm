# This code is part of Perl distribution OODoc version 3.02.
# The POD got stripped from this file by OODoc version 3.02.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package OODoc::Text::Structure;{
our $VERSION = '3.02';
}

use parent 'OODoc::Text';

use strict;
use warnings;

use Log::Report    'oodoc';
use List::Util     'first';

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args) or return;
	$self->{OTS_subs}  = [];
	$self->{OTS_level} = delete $args->{level} or panic;
	$self;
}


sub emptyExtension($)
{	my ($self, $container) = @_;

	my $new = ref($self)->new(
		name      => $self->name,
		linenr    => -1,
		level     => $self->level,
		container => $container,
	);
	$new->extends($self);
	$new;
}

#--------------------

sub level()   { $_[0]->{OTS_level} }


sub niceName()
{	my $name = shift->name;
	$name =~ m/[a-z]/ ? $name : ucfirst(lc $name);
}

#--------------------

sub path() { panic "Not implemented" }


sub findEntry($) { panic "Not implemented" }

#--------------------

sub all($@)
{	my ($self, $method) = (shift, shift);
	$self->$method(@_);
}


sub isEmpty()
{	my $self = shift;

	my $manual = $self->manual;
	return 0 if $self->description !~ m/^\s*$/;
	return 0 if first { !$manual->inherited($_) }
		$self->examples, $self->subroutines;

	my @nested
	  = $self->isa('OODoc::Text::Chapter')    ? $self->sections
	  : $self->isa('OODoc::Text::Section')    ? $self->subsections
	  : $self->isa('OODoc::Text::SubSection') ? $self->subsubsections
	  : return 1;

	not first { !$_->isEmpty } @nested;
}

sub publish($$)
{	my ($self, $args) = @_;
	my $p = $self->SUPER::publish($args);
	$p->{level} = $self->level;
	$p->{path}  = $self->path;

	my @n = map $_->publish($args)->{id}, $self->nest;
	$p->{nest} = \@n if @n;

	my @s = map $_->publish($args)->{id}, $self->subroutines;
	$p->{subroutines} = \@s if @s;
	$p;
}

#--------------------

sub addSubroutine(@)
{	my $self = shift;
	my $subs = $self->{OTS_subs} ||= [];

	foreach my $sub (@_)
	{	$sub->container($self);

		my $name = $sub->name;
		if(my $has = first { $_->name eq $name } @$subs)
		{	warn "WARNING: name '$name' seen before, lines ".$has->linenr. " and " . $sub->linenr . "\n";
		}
		push @{$self->{OTS_subs}}, $sub;
	}

	$self;
}


sub subroutines() { @{ $_[0]->{OTS_subs}} }


sub subroutine($)
{	my ($self, $name) = @_;
	first {$_->name eq $name} $self->subroutines;
}


sub setSubroutines($)
{	my $self = shift;
	$self->{OTS_subs} = shift || [];
}

1;
