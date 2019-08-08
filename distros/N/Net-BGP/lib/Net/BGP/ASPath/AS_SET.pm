#!/usr/bin/perl

package Net::BGP::ASPath::AS_SET;

use strict;

## Inheritance and Versioning ##

@Net::BGP::ASPath::AS_SET::ISA = qw( Net::BGP::ASPath::AS );
our $VERSION = '0.17';

sub type {
    return 1;
}

sub length {
    my $this = shift;

    # We really shouldn't see empty ones of these, but if we do,
    # we will treat them as zero.  But otherwise, RFC indicates
    # that in path computations, any AS_SET is equal to one hop.

    if (scalar(keys %$this)) {
        return 1;
    } else {
        return 0;
    }
}

sub asstring { as_string(@_) }

sub as_string {
    my $this = shift;
    return '{' . join(',', sort { $a <=> $b } keys %{$this}) . '}';
}

sub asarray {
    my $this = shift;
    return [ sort { $a <=> $b } keys %{$this} ];
}

sub merge {
    my $this = shift;
    foreach my $obj (@_) {
        foreach my $as (@{$obj}) {
            $this->{$as} = 1;
        }
    }
    return $this;
}

sub count {
    my $this = shift;

    return scalar(@{$this});
}

1;

