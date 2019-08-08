#!/usr/bin/perl

package Net::BGP::ASPath::AS_SEQUENCE;

use strict;

## Inheritance and Versioning ##

@Net::BGP::ASPath::AS_SEQUENCE::ISA = qw( Net::BGP::ASPath::AS );
our $VERSION = '0.17';

sub type {
    return 2;
}

sub length {
    my $this = shift;
    return scalar @{$this};
}

sub asstring { as_string(@_) }

sub as_string {
    my $this = shift;
    return join(' ', @{$this});
}

sub asarray {
    my $this = shift;
    return [ @{$this} ];    # Unblessed version of list!
}

sub count {
    my $this = shift;

    return scalar(@{$this});
}

sub remove_tail {
    my ($this, $cnt) = @_;

    while ($cnt-- > 0) {
        pop @{$this};
    }

    return $this;
}

1;

