package Net::Cisco::ObjectGroup::ICMP;
use base qw(Net::Cisco::ObjectGroup::Base);

use strict;
use warnings FATAL => qw(all);

use Carp;

sub _init {
    my $self    = shift;
    my $arg_ref = shift;

    $self->set_type( 'icmp-type' );
    $self->SUPER::_init( $arg_ref );

    return $self;
}

sub push {
    my $self    = shift;
    my $arg_ref = shift;

    croak 'must specify either group-object or ICMP type'
        if !defined $arg_ref->{group_object}
        and !defined $arg_ref->{icmp_type};

    croak 'cannot specify both group-object and ICMP type'
        if defined $arg_ref->{group_object}
        and defined $arg_ref->{icmp_type};

    croak 'bad group-object'
        if defined $arg_ref->{group_object}
        and ! UNIVERSAL::isa( $arg_ref->{group_object}, __PACKAGE__ );


    $arg_ref->{icmp_type}
        = __PACKAGE__->__dict->{$arg_ref->{icmp_type}}
        if defined $arg_ref->{icmp_type}
        and defined __PACKAGE__->__dict
        and exists __PACKAGE__->__dict->{$arg_ref->{icmp_type}};

    my $line = defined $arg_ref->{icmp_type}
             ? "icmp-object $arg_ref->{icmp_type}"
             : 'group-object '. $arg_ref->{group_object}->get_name;

    push @{$self->get_objs}, $line;

    return $self;
}

1;

# Copyright (c) The University of Oxford 2006. All Rights Reserved.
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
# 
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 51
# Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

__DATA__
---
0   : echo-reply
3   : unreachable
4   : source-quench
5   : redirect
6   : alternate-address
8   : echo
9   : router-advertisement
10  : router-solicitation
11  : time-exceeded
12  : parameter-problem
13  : timestamp-request
14  : timestamp-reply
15  : information-request
16  : information-reply
17  : mask-request
18  : mask-reply
31  : conversion-error
32  : mobile-redirect
