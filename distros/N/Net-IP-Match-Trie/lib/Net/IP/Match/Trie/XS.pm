# -*- mode: coding: utf-8; -*-
package Net::IP::Match::Trie;

use strict;
use warnings;

our $VERSION = '1.00';

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub new {
    my($class, %opt) = @_;
    my $self = bless {}, $class;
    $self->_initialize();
    return $self;
}

# name => [ cidr1, cidr2, ... ]
sub add {
    my($self, $name, $cidrs) = @_;

    for my $cidr (@$cidrs) {
        my($network, $netmask) = split m{/}, $cidr;
        $netmask ||= 32;
        $self->_add($name, $network, $netmask);
    }
}

sub impl {
    my($self) = @_;
    return "XS";
}

1;
