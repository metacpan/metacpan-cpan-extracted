#!/usr/bin/perl

package Net::BGP::ASPath::AS_CONFED_SET;

use Net::BGP::ASPath::AS_SET;

use strict;

## Inheritance and Versioning ##

@Net::BGP::ASPath::AS_CONFED_SET::ISA = qw( Net::BGP::ASPath::AS_SET );
our $VERSION = '0.16';

sub type {
    return 4;
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

1;

