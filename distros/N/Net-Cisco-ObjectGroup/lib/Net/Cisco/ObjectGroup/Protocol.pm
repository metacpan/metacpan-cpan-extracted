package Net::Cisco::ObjectGroup::Protocol;
use base qw(Net::Cisco::ObjectGroup::Base);

use strict;
use warnings FATAL => qw(all);

use Carp;

sub push {
    my $self    = shift;
    my $arg_ref = shift;

    croak 'must specify either group-object or protocol'
        if !defined $arg_ref->{group_object}
        and !defined $arg_ref->{protocol};

    croak 'cannot specify both group-object and protocol'
        if defined $arg_ref->{group_object}
        and defined $arg_ref->{protocol};

    croak 'bad group-object'
        if defined $arg_ref->{group_object}
        and ! UNIVERSAL::isa( $arg_ref->{group_object}, __PACKAGE__ );


    $arg_ref->{protocol}
        = __PACKAGE__->__dict->{$arg_ref->{protocol}}
        if defined $arg_ref->{protocol}
        and defined __PACKAGE__->__dict
        and exists __PACKAGE__->__dict->{$arg_ref->{protocol}};

    my $line = defined $arg_ref->{protocol}
             ? "protocol-object $arg_ref->{protocol}"
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
0   : ip
1   : icmp
2   : igmp
4   : ipinip
6   : tcp
9   : igrp
17  : udp
47  : pptp
47  : gre
50  : esp
50  : ipsec
51  : ah
58  : icmp6
88  : eigrp
89  : ospf
94  : nos
103 : pim
108 : pcp
109 : snp
