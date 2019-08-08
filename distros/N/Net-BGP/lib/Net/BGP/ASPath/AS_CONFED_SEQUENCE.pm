#!/usr/bin/perl

package Net::BGP::ASPath::AS_CONFED_SEQUENCE;

use Net::BGP::ASPath::AS_SEQUENCE;

use strict;

## Inheritance and Versioning ##

@Net::BGP::ASPath::AS_CONFED_SEQUENCE::ISA =
  qw( Net::BGP::ASPath::AS_SEQUENCE );

our $VERSION = '0.17';

sub type {
    return 3;
}

sub length {
    return 0;
}

sub asstring { as_string(@_) }

sub as_string {
    return '(' . shift->SUPER::as_string . ')';
}

sub count {
    my $self = shift;

    return scalar($self->SUPER::count);
}

sub remove_tail {
    my $self = shift;

    return $self->SUPER::remove_tail(@_);
}

1;

