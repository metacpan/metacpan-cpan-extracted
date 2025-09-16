# This code is part of Perl distribution OODoc version 3.04.
# The POD got stripped from this file by OODoc version 3.04.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package OODoc::Text;{
our $VERSION = '3.04';
}

use parent 'OODoc::Object';

use strict;
use warnings;

use Log::Report    'oodoc';

#--------------------

use overload
	'""'   => sub {$_[0]->name},
	'cmp'  => sub {$_[0]->name cmp "$_[1]"};

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args) or return;

	$self->{OT_name}     = delete $args->{name};

	my $nr = $self->{OT_linenr} = delete $args->{linenr} or panic;
	$self->{OT_type}     = delete $args->{type} or panic;

	exists $args->{container}   # may be explicit undef
		or panic "no text container specified for the ".(ref $self)." object";

	$self->{OT_container}= delete $args->{container};    # may be undef initially
	$self->{OT_descr}    = delete $args->{description} || '';
	$self->{OT_examples} = [];
	$self->{OT_extends}  = [];
	$self;
}

#--------------------

sub name() { $_[0]->{OT_name} }


sub type() { $_[0]->{OT_type} }


sub description()
{	my @lines = split /^/m, shift->{OT_descr};
	shift @lines while @lines && $lines[ 0] =~ m/^\s*$/;
	pop   @lines while @lines && $lines[-1] =~ m/^\s*$/;
	join '', @lines;
}


sub container(;$)
{	my $self = shift;
	@_ ? ($self->{OT_container} = shift) : $self->{OT_container};
}


sub linenr() { $_[0]->{OT_linenr} }


sub where()
{	my $self = shift;
	( $self->manual->source, $self->linenr );
}


sub manual(;$)
{	my $self = shift;
	$self->container->manual;
}


sub extends(;$)
{	my $self = shift;
	my $ext  = $self->{OT_extends};
	push @$ext, @_;

	wantarray ? @$ext : $ext->[0];
}

#--------------------

sub openDescription() { \shift->{OT_descr} }


sub findDescriptionObject()
{	my $self   = shift;
	return $self if length $self->description;

	my @descr = map $_->findDescriptionObject, $self->extends;
	wantarray ? @descr : $descr[0];
}


sub addExample($)
{	my ($self, $example) = @_;
	push @{$self->{OT_examples}}, $example;
	$example;
}


sub examples() { @{ $_[0]->{OT_examples}} }

sub publish($%)
{	my ($self, $args) = @_;
	my $exporter = $args->{exporter} or panic;
	my $manual   = $args->{manual}   or panic;

	my $p = $self->SUPER::publish($args);
	$p->{type}      = $exporter->markup(lc $self->type);
	$p->{inherited} = $exporter->boolean($manual->inherited($self));

	if(my $name  = $self->name)
	{	$p->{name} = $exporter->markupString($name);
	}

	my $descr    = $self->description // '';
	$p->{intro}  = $exporter->markupBlock($descr)
		if length $descr;

	my @e        = map $_->publish($args)->{id}, $self->examples;
	$p->{examples} = \@e if @e;
	$p;
}

1;
