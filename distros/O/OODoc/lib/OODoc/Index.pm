# This code is part of Perl distribution OODoc version 3.05.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package OODoc::Index;{
our $VERSION = '3.05';
}

use parent 'OODoc::Object';

use strict;
use warnings;

use Log::Report    'oodoc';

use List::Util     qw/first/;

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);
	$self->{OI_pkgs} = {};
	$self->{OI_mans} = {};
	$self;
}

#--------------------

sub _packages() { $_[0]->{OI_pkgs} }
sub _manuals()  { $_[0]->{OI_mans} }

#--------------------

sub addManual($)
{	my ($self, $manual) = @_;

	ref $manual && $manual->isa('OODoc::Manual')
		or panic "manual definition requires manual object";

	push @{$self->_packages->{$manual->package}}, $manual;
	$self->_manuals->{$manual->name} = $manual;
	$self;
}


sub mainManual($)
{	my ($self, $name) = @_;
	first { $_ eq $_->package } $self->manualsForPackage($name);
}


sub manualsForPackage($)
{	my ($self, $name) = @_;
	@{$self->_packages->{$name || 'doc'} || []};
}


sub manuals() { values %{$_[0]->_manuals} }


sub findManual($) { $_[0]->_manuals->{ $_[1] } }


sub packageNames() { keys %{$_[0]->_packages} }


1;
