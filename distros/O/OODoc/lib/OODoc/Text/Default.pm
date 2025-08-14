# This code is part of Perl distribution OODoc version 3.01.
# The POD got stripped from this file by OODoc version 3.01.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

package OODoc::Text::Default;{
our $VERSION = '3.01';
}

use parent 'OODoc::Text';

use strict;
use warnings;

use Log::Report    'oodoc';


sub init($)
{   my ($self, $args) = @_;
    $args->{type}    ||= 'Default';
    $args->{container} = delete $args->{subroutine} or panic;

    $self->SUPER::init($args)
        or return;

    $self->{OTD_value} = delete $args->{value};
    defined $self->{OTD_value} or panic;

    $self;
}

sub publish($)
{   my ($self, $args) = @_;
    my $exporter = $args->{exporter};

    my $p = $self->SUPER::publish($args);
    $p->{value} = $exporter->markupString($self->value);
    $p;
}

#-------------------------------------------

sub subroutine() { $_[0]->container }


sub value() { $_[0]->{OTD_value} }

1;
