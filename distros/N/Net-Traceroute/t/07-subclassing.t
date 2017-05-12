#!/usr/bin/perl

# Test that subclassing works

package main;

use strict;
use warnings;

use Test::More tests => 2;

use Net::Traceroute;

package Net::Traceroute::Subclass;

use base qw(Net::Traceroute);

# This subclass lets Net::Traceroute allocate the ref.
sub new {
    my $type = shift;
    return $type->SUPER::new(@_);
}

package Net::Traceroute::SubclassAlloc;

use base qw(Net::Traceroute);

# This subclass allocates its own ref.
sub new {
    my $type = shift;
    my $self = bless {}, $type;
    return $self->SUPER::new(@_);
}

package main;

isa_ok(Net::Traceroute::SubclassAlloc->new(), "Net::Traceroute::SubclassAlloc",
     "SubclassAlloc returns a SubclassAlloc");
isa_ok(Net::Traceroute::Subclass->new(), "Net::Traceroute::Subclass",
     "Subclass returns a Subclass");
