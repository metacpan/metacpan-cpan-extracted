package SignalWire::Agents::Contexts::ContextBuilder;
# Copyright (c) 2025 SignalWire
# Licensed under the MIT License.
# Stub: full implementation provided by another agent.

use strict;
use warnings;
use Moo;

has _contexts => (is => 'rw', default => sub { {} });

sub add_context {
    my ($self, $name, %opts) = @_;
    $self->_contexts->{$name} = \%opts;
    return $self;
}

sub has_contexts {
    my ($self) = @_;
    return scalar(keys %{ $self->_contexts }) ? 1 : 0;
}

sub to_hashref {
    my ($self) = @_;
    return $self->_contexts;
}

1;
