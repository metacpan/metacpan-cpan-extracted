# This code is part of Perl distribution OODoc version 3.00.
# The POD got stripped from this file by OODoc version 3.00.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

package OODoc::Text::SubSubSection;{
our $VERSION = '3.00';
}

use parent 'OODoc::Text::Structure';

use strict;
use warnings;

use Log::Report    'oodoc';


sub init($)
{   my ($self, $args) = @_;
    $args->{type}      ||= 'Subsubsection';
    $args->{container} ||= delete $args->{subsection} or panic;
    $args->{level}     ||= 3;

    $self->SUPER::init($args)
        or return;

    $self;
}

sub findEntry($)
{  my ($self, $name) = @_;
   $self->name eq $name ? $self : ();
}

sub nest() { }

#--------------

sub subsection() { shift->container }


sub chapter() { shift->subsection->chapter }

sub path()
{   my $self = shift;
    $self->subsection->path . '/' . $self->name;
}

1;
