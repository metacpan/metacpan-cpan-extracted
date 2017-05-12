package Net::Cisco::ObjectGroup::Service;
use base qw(Net::Cisco::ObjectGroup::Base);

use warnings FATAL => qw(all);
use strict;

use Carp;

sub _init {
    my $self    = shift;
    my $arg_ref = shift;

    croak 'missing parameter "protocol" when creating service group'
        if !defined $arg_ref->{protocol};

    croak "unrecognized protocol type: '$arg_ref->{protocol}'"
        if $arg_ref->{protocol} !~ m/^(?:tcp|udp|tcp-udp)$/;

    $self->set_name( $self->get_name ." $arg_ref->{protocol}" );
    $self->SUPER::_init( $arg_ref );

    return $self;
}

sub push {
    my $self    = shift;
    my $arg_ref = shift;

    croak 'must specify either group-object or service definition'
        if !defined $arg_ref->{group_object} and !defined $arg_ref->{svc};

    croak 'cannot specify both group-object and service definition'
        if defined $arg_ref->{group_object} and defined $arg_ref->{svc};

    croak 'missing service operator'
        if defined $arg_ref->{svc} and !defined $arg_ref->{svc_op};

    croak "unrecognized service operator: '$arg_ref->{svc_op}'"
        if defined $arg_ref->{svc_op}
        and $arg_ref->{svc_op} !~ m/^(?:eq|range)$/;

    croak 'bad group-object'
        if defined $arg_ref->{group_object}
        and ! UNIVERSAL::isa( $arg_ref->{group_object}, __PACKAGE__ );


    if (defined $arg_ref->{svc}
        and defined __PACKAGE__->__dict
        and exists __PACKAGE__->__dict->{$arg_ref->{svc}}) {

        $arg_ref->{svc} = __PACKAGE__->__dict->{$arg_ref->{svc}};
    }

    if (defined $arg_ref->{svc_hi}
        and defined __PACKAGE__->__dict
        and exists __PACKAGE__->__dict->{$arg_ref->{svc_hi}}) {

        $arg_ref->{svc_hi} = __PACKAGE__->__dict->{$arg_ref->{svc_hi}};
    }

    my $line = defined $arg_ref->{group_object}
        ? 'group-object '. $arg_ref->{group_object}->get_name
        : defined $arg_ref->{svc_hi}
        ? "port-object $arg_ref->{svc_op} $arg_ref->{svc} $arg_ref->{svc_hi}"
        : "port-object $arg_ref->{svc_op} $arg_ref->{svc}";

    $line =~ s/ \S+$// if defined $arg_ref->{group_object}; # chop off proto

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
7   : echo
9   : discard
49  : tacacs
53  : domain
80  : www
111 : sunrpc
496 : pim-auto-rp
517 : talk
750 : kerberos


#    7   : echo
#    9   : discard
#    13  : daytime
#    19  : chargen
#    20  : ftp-data
#    21  : ftp
#    22  : ssh
#    23  : telnet
#    25  : smtp
#    37  : time
#    42  : nameserver
#    43  : whois
#    49  : tacacs
#    53  : domain
#    67  : bootps
#    68  : bootpc
#    69  : tftp
#    70  : gopher
#    79  : finger
#    80  : www
#    101 : hostname
#    109 : pop2
#    110 : pop3
#    111 : sunrpc
#    113 : ident
#    119 : nntp
#    123 : ntp
#    137 : netbios-ns
#    138 : netbios-dgm
#    139 : netbios-ssn
#    143 : imap4
#    161 : snmp
#    162 : snmptrap
#    177 : xdmcp
#    179 : bgp
#    194 : irc
#    195 : dnsix
#    389 : ldap
#    434 : mobile-ip
#    443 : https
#    496 : pim-auto-rp
#    500 : isakmp
#    512 : biff
#    512 : exec
#    513 : login
#    513 : who
#    514 : cmd
#    514 : syslog
#    515 : lpd
#    517 : talk
#    520 : rip
#    540 : uucp
#    543 : klogin
#    544 : kshell
#    636 : ldaps
#    750 : kerberos
#    1352 : lotusnotes
#    1494 : citrix-ica
#    1521 : sqlnet
#    1645 : radius
#    1646 : radius-acct
#    1720 : h323
#    1723 : pptp
#    2748 : ctiqbe
#    5190 : aol
#    5510 : secureid-udp
#    5631 : pcanywhere-data
#    5632 : pcanywhere-status
