# This code is part of Perl distribution OODoc version 3.01.
# The POD got stripped from this file by OODoc version 3.01.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

package OODoc::Text::SubSection;{
our $VERSION = '3.01';
}

use parent 'OODoc::Text::Structure';

use strict;
use warnings;

use Log::Report    'oodoc';


sub init($)
{   my ($self, $args) = @_;
    $args->{type}      ||= 'Subsection';
    $args->{container} ||= delete $args->{section} or panic;
    $args->{level}     ||= 3;

    $self->SUPER::init($args) or return;
    $self->{OTS_subsubsections} = [];
    $self;
}

sub emptyExtension($)
{   my ($self, $container) = @_;
    my $empty = $self->SUPER::emptyExtension($container);
    my @subsub = map $_->emptyExtension($empty), $self->subsubsections;
    $empty->subsubsections(@subsub);
    $empty;
}

sub findEntry($)
{  my ($self, $name) = @_;
   $self->name eq $name ? $self : ();
}

#-------------------------------------------

sub section() { shift->container }


sub chapter() { shift->section->chapter }

sub path()
{   my $self = shift;
    $self->section->path . '/' . $self->name;
}

#-------------------------------------------

sub subsubsection($)
{   my ($self, $thing) = @_;

    if(ref $thing)
    {   push @{$self->{OTS_subsubsections}}, $thing;
        return $thing;
    }

    first { $_->name eq $thing } $self->subsubsections;
}


sub subsubsections(;@)
{   my $self = shift;
    if(@_)
    {   $self->{OTS_subsubsections} = [ @_ ];
        $_->container($self) for @_;
    }

    @{$self->{OTS_subsubsections}};
}

*nest = \*subsubsections;

#--------------------

1;

1;
