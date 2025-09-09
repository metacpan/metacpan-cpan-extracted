# This code is part of Perl distribution OODoc version 3.03.
# The POD got stripped from this file by OODoc version 3.03.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package OODoc::Text::SubSubSection;{
our $VERSION = '3.03';
}

use parent 'OODoc::Text::Structure';

use strict;
use warnings;

use Log::Report    'oodoc';

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$args->{type}      ||= 'Subsubsection';
	$args->{container} ||= delete $args->{subsection} or panic;
	$args->{level}     ||= 4;
	$self->SUPER::init($args);
}

sub findEntry($)
{	my ($self, $name) = @_;
	$self->name eq $name ? $self : ();
}

sub nest() { }

#--------------------

sub subsection() { $_[0]->container }


sub chapter() { $_[0]->subsection->chapter }

sub path()
{	my $self = shift;
	$self->subsection->path . '/' . $self->name;
}

1;
