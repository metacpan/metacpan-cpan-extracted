package Net::Cisco::ObjectGroup::Network;
use base qw(Net::Cisco::ObjectGroup::Base);

use strict;
use warnings FATAL => qw(all);

use Carp;

sub push {
    my $self    = shift;
    my $arg_ref = shift;

    croak 'must specify either group-object or IP network'
        if !defined $arg_ref->{group_object}
        and !defined $arg_ref->{net_addr};

    croak 'cannot specify both group-object and IP network'
        if defined $arg_ref->{group_object}
        and defined $arg_ref->{net_addr};

    croak 'bad group-object'
        if defined $arg_ref->{group_object}
        and ! UNIVERSAL::isa( $arg_ref->{group_object}, __PACKAGE__ );

    my $line = defined $arg_ref->{group_object}
             ? 'group-object '. $arg_ref->{group_object}->get_name
             : defined $arg_ref->{netmask}
             ? "network-object $arg_ref->{net_addr} $arg_ref->{netmask}"
             : "network-object host $arg_ref->{net_addr}";

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
