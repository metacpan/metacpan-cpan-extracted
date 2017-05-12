# -*- mode: cperl; cperl-indent-level: 4; -*-
# vi:ai:sm:et:sw=4:ts=4

# $Id: IPTables.pm,v 1.9 2005/11/18 23:40:00 paulv Exp $

package POE::Filter::Log::IPTables;

use strict;
use warnings;
use POE::Filter::Line;
use Carp qw(carp croak);

our $VERSION = '0.02';

sub new {
    my $class = shift;

    croak "$class requires an even number of parameters" if @_ and @_ & 1;

    my %params = @_;

    my $self = {};

    $self->{line} = POE::Filter::Line->new();

    # the types of ICMP messages that require us to do further
    # processing
    $self->{icmp_types} = ['3',  # destination unreachable
                           '4',  # source quench
                           '11', # time exceeded
                          ];
    
    if (defined $params{Debug} and $params{Debug} > 0) {
        $self->{debug} = 1;
    } else {
        $self->{debug} = 0;
    }

    if (defined $params{Syslog} and $params{Syslog} > 0) {
        $self->{syslog} = 1;
    } else {
        $self->{syslog} = 0;
    }
    
    bless ($self, $class);
    return $self;
}

sub get {
    my $self = shift;
    my $chunk = shift;
    my @queue;

    my $lines = $self->{line}->get($chunk);
    foreach my $line (@$lines) {
        push(@queue, $self->_parse($line));
    }
    return \@queue;
}

sub _parse {
    my $self = shift;
    my $line = shift;
    
    my $ds;
    my $leftover;
    
    # save the whole line so the user can twiddle it if she wants.
    $ds->{line} = $line;

    # strip off syslog stuff
    if ($self->{syslog}) {
        # Jan 11 17:30:35 hostname kernel:
        $line =~ s/^\w\w\w\s+\d+ \d\d:\d\d:\d\d (?:\w|-|\.|_)+ //;
    }

    # remove prefix
    $line =~ s/kernel: (.{0,29}) ?IN/IN/;
    
    # IN, OUT, and MAC
    print "base: [$line]\n" if $self->{debug};
    
    # inbound interface
    if ($line =~ /^IN=(\w+)? /) {
        $ds->{in_int} = $1;

        if ($1) {
            $line =~ s/IN=$1 //;
        } else {
            $line =~ s/IN= //;
        }
    }

    # outbound interface
    if ($line =~ / ?OUT=([A-Za-z0-9]+)? /) {
        $ds->{out_int} = $1;

        if ($1) {
            $line =~ s/ ?OUT=$1 //;
        } else {
            $line =~ s/ ?OUT= //;
        }
    }

    # input MAC address
    if ($line =~ / ?MAC=([0-9A-F:]+)? /i) {
        $ds->{mac} = $1;

        if ($1) {
            $line =~ s/ ?MAC=$1 //;
        } else {
            $line =~ s/ ?MAC= //;
        }
    }

    print "BASE done: [$line]\n" if $self->{debug};
    
    # the IP header
    ($line, $ds->{ip}) = $self->_parseIP($line);

    # everything else

    # ICMP has to be done first because ICMP messages sometimes have IP
    # headers in them.
    if ($line =~/ ?PROTO=ICMP /) {
        $line =~ s/^PROTO=ICMP //g;
        $ds->{ip}->{type} = "icmp";
        ($ds->{ip}->{icmp}, $leftover) = $self->_parseICMP($line);
    } elsif ($line =~ / ?PROTO=TCP /) {
        $line =~ s/^PROTO=TCP //g;
        $ds->{ip}->{type} = "tcp";
        ($ds->{ip}->{tcp}, $leftover) = $self->_parseTCP($line);
    } elsif ($line =~/ ?PROTO=UDP /) {
        $line =~ s/^PROTO=UDP //g;
        $ds->{ip}->{type} = "udp";
        ($ds->{ip}->{udp}, $leftover) = $self->_parseUDP($line);
    } else {
#        $line =~ s/^PROTO=//g;
        ($ds->{ip}->{type}, $leftover) = $self->_parseUnknown($line);
    }

    $ds->{leftover} = $leftover;
    
    return $ds;
}

sub _parseIP {
    my $self = shift;
    my $line = shift;
    my $ds;

    print "IP: [$line]\n" if $self->{debug};
    
    # source address
    if ($line =~ / ?SRC=(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) /) {
        $ds->{src_addr} = $1;
        $line =~ s/ ?SRC=$1 //;
    }

    # destination address
    if ($line =~ / ?DST=(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) /) {
        $ds->{dst_addr} = $1;
        $line =~ s/ ?DST=$1 //;
    }

    # length
    if ($line =~ / ?LEN=(\d+) /) {
        $ds->{len} = $1;
        $line =~ s/ ?LEN=$1 //;
    }

    # type of service
    if ($line =~ / ?TOS=(0x[0-9A-Z]{2}) /i) {
        $ds->{tos} = $1;
        $line =~ s/ ?TOS=$1 //;
    }

    # PREC?
    if ($line =~ / ?PREC=(0x[0-9A-Z]{2}) /i) {
        $ds->{prec} = $1;
        $line =~ s/ ?PREC=$1 //;
    }

    # time to live
    if ($line =~ / ?TTL=(\d+) /) {
        $ds->{ttl} = $1;
        $line =~ s/ ?TTL=$1 //;
    }

    # ip id
    if ($line =~ / ?ID=(\d+) /) {
        $ds->{id} = $1;
        $line =~ s/ ?ID=$1 //;
    }

    # congestion
    if ($line =~ /^CE /) {
        push(@{$ds->{fragment_flags}}, "CE");
        $line =~ s/^CE //;
    }

    # don't fragment
    if ($line =~ /^DF /) {
        push(@{$ds->{fragment_flags}}, "DF");
        $line =~ s/^DF //;
    }

    # more fragments
    if ($line =~ /^MF /) {
        push(@{$ds->{fragment_flags}}, "MF");
        $line =~ s/^MF //;
    }

    print "IP done: [$line]\n" if $self->{debug};
    
    return ($line, $ds);
}

sub _parseTCP {
    my $self = shift;
    my $line = shift;
    my $ds;

    print "TCP: [$line]\n" if $self->{debug};
    
    # SPT=36073 DPT=22 WINDOW=5840 RES=0x00 SYN URGP=0

    # source port
    if ($line =~ /SPT=(\d+) /) {
        $ds->{src_port} = $1;
        $line =~ s/SPT=$1 //;
    }

    # destination port
    if ($line =~ /DPT=(\d+) /) {
        $ds->{dst_port} = $1;
        $line =~ s/DPT=$1 //;
    }

    # window length
    if ($line =~ /WINDOW=(\d+) /) {
        $ds->{window} = $1;
        $line =~ s/WINDOW=$1 //;
    }

    # reserved bits
    if ($line =~ /RES=(0x[0-9A-Z]{2}) /i) {
        $ds->{res} = $1;
        $line =~ s/RES=$1 //;
    }

    # flags
    #
    # CWR ECE URG ACK PSH RST SYN FIN
    # CWR - Congestion Window Reduced
    # ECE - Explicit Congestion Notification echo
    # URG - Urgent
    # ACK - Acknowledgement
    # PSH - Push
    # RST - Reset
    # SYN - Synchronize
    # FIN - Finished
    
    if ($line =~ /CWR /) {
        push(@{$ds->{flags}}, "CWR");
        $line =~ s/CWR //;
    }

    if ($line =~ /ECE /) {
        push(@{$ds->{flags}}, "ECE");
        $line =~ s/ECE //;
    }

    if ($line =~ /URG /) {
        push(@{$ds->{flags}}, "URG");
        $line =~ s/URG //;
    }

    if ($line =~ /ACK /) {
        push(@{$ds->{flags}}, "ACK");
        $line =~ s/ACK //;
    }

    if ($line =~ /PSH /) {
        push(@{$ds->{flags}}, "PSH");
        $line =~ s/PSH //;
    }
    
    if ($line =~ /RST /) {
        push(@{$ds->{flags}}, "RST");
        $line =~ s/RST //;
    }

    if ($line =~ /SYN /) {
        push(@{$ds->{flags}}, "SYN");
        $line =~ s/SYN //;
    }

    if ($line =~ /FIN /) {
        push(@{$ds->{flags}}, "FIN");
        $line =~ s/FIN //;
    }

    # urgent pointer

    if ($line =~ /URGP=(\d+) ?/) {
        $ds->{urgp} = $1;
        $line =~ s/URGP=$1 ?//;
    }

    print "TCP done: [$line]\n" if $self->{debug};

    if ($line and $line !~ /^\s+$/) {
        return ($ds, $line);
    } else {
        return ($ds, undef);
    }
}

sub _parseUDP {
    my $self = shift;
    my $line = shift;
    my $ds;

    print "UDP: [$line]\n" if $self->{debug};
    
    # SPT=10890 DPT=33440 LEN=12

    # source port
    if ($line =~ /SPT=(\d+) /) {
        $ds->{src_port} = $1;
        $line =~ s/SPT=$1 //;
    }

    # destination port
    if ($line =~ /DPT=(\d+) /) {
        $ds->{dst_port} = $1;
        $line =~ s/DPT=$1 //;
    }

    # length
    if ($line =~ /LEN=(\d+) ?/) {
        $ds->{len} = $1;
        $line =~ s/LEN=$1 ?//;
    }

    print "UDP done: [$line]\n" if $self->{debug};

    if ($line and $line !~ /^\s+$/) {
        return ($ds, $line);
    } else {
        return ($ds, undef);
    }

}

sub _parseICMP {
    my $self = shift;
    my $line = shift;
    my $ds;

    print "ICMP: [$line]\n" if $self->{debug};

    if ($line =~ /TYPE=(\d+) /) {
        $ds->{type} = $1;
        $line =~ s/TYPE=$1 //;
    }

    if ($line =~ /CODE=(\d+) /) {
        $ds->{code} = $1;
        $line =~ s/CODE=$1 //;
    }

    my $packet;
    foreach my $type (@{$self->{icmp_types}}) {

        if ($type == $ds->{type}) {
            if ($line =~ /\[(.+)\]/) {
                $packet = $1;
                $ds->{error_header} = $self->_parse($packet);
            } else {
                carp("got a ICMP packet with type of $type, but couldn't " .
                     "extract the IP header...");
            }
        }
    }

    # strip out the thing
    if ($packet) {
        my $quoted = quotemeta($packet);
        $line =~ s/\[$quoted\]//;
    }

    if ($line =~ /ID=(\d+) /) {
        $ds->{id} = $1;
        $line =~ s/ID=$1 //;
    }

    if ($line =~ /SEQ=(\d+) ?/) {
        $ds->{seq} = $1;
        $line =~ s/SEQ=$1 ?//;
    }
    
    print "ICMP done: ($line)\n" if $self->{debug};

    if ($line and $line !~ /^\s+$/) {
        return ($ds, $line);
    } else {
        return ($ds, undef);
    }
}

sub _parseUnknown {
    my $self = shift;
    my $line = shift;
    my $proto;

    if ($line =~ /PROTO=(\w+) ?/) {
        $proto = (getprotobynumber($1))[0];

        if (not defined($proto)) {
            $proto = "unknown";
        }

        $line =~ s/PROTO=$1 ?//;
    }

    if ($line and $line !~ /^\s+$/) {
        return ($proto, $line);
    } else {
        return ($proto, undef);
    }
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

POE::Filter::Log::IPTables - filter for processing IPTables logs

=head1 SYNOPSIS

  use POE::Filter::Log::IPTables;

  $filter = POE::Filter::Log::IPTables->new(Syslog => 1);
  $arrayref_of_hashrefs = $filter->get($arrayref_of_raw_chunks_from_driver);

=head1 DESCRIPTION

The Log::IPTables filter translates iptables log lines into hashrefs.

=head1 PUBLIC FILTER METHODS

=over 2

=item new

new() creates and initializes a new POE::Filter::Log::IPTables filter.
You can pass it "Syslog => 1" if you would like it to attempt to remove
syslog timestamps from the log lines. You can pass it "Debug => 1" to
turn debugging on.

=item get ARRAYREF

get() translates iptables log lines into hashrefs.

In the top level of the hashref:

=over 4

=item in_int

The interface a packet came in on.

=item out_int

The interface a packet went out on.

=item leftover

Any part of the iptables log line that couldn't be parsed.

=item line

The entire (unmodified) iptables log line.

=item ip

=over 4

=item src_addr

The source address of the IP packet.

=item dst_addr

The destination address of the IP packet.

=item len

The length of the IP packet.

=item tos

The Type of Service of the IP packet.

=item prec

The Precedence of the IP packet.

=item ttl

The time to live of the IP packet.

=item id

The id of the IP packet.

=item fragment_flags

An arrayref. Can have "CE" (congestion), "DF" (don't fragment), or "MF"
(more fragments are coming).

=item type

The name/number of the protocol that the IP packet encapsulates. This
will be 'tcp', 'udp', 'icmp', or a number corresponding to the protocol
in /etc/protocols.

=item tcp

=over 4

=item src_port

The source port of the tcp packet.

=item dst_port

The destination port of the tcp packet.

=item window

The length of the TCP window.

=item res

The reserved bits.

=item flags

An arrayref. Can be any combination of "CWR" (Congestion Window
Reduced), "ECE" (Explicit Congestion Notification Echo), "URG" (Urgent),
"ACK" (Acknowledgement), "PSH" (Push), "RST" (Reset), "SYN"
(Synchronize), or "FIN" (Finished)

=item urgp

The urgent pointer.

=back

=item udp

=over 4

=item src_port

The source port of the UDP packet.

=item dst_port

The destination port of the UDP packet.

=item len

The length of the UDP packet.

=back

=item icmp

=over 4

=item type

The numeric type of the ICMP packet.

=item code

The numeric code of the ICMP packet. 

=item error_header

Some types of ICMP - 3 (destination unreachable), 4 (source quench), and
11 (time exceeded) - contain the IP and protocol headers that generated
the ICMP packet. We parse this recursively, so if the type is one of
those numbers, error_header is a hashref that starts again with the top
level of the data structure. It may make more sense if you look at a
YAML dump, which can be found below...

=item id

The id of the ICMP echo packet.

=item seq

The sequence number of the ICMP echo packet.

=back

=back

=back

=back

=head1 DATA STRUCTURE OVERVIEW

=head2 TCP packet

    in_int: eth1
    leftover: ~
    line: >-
      Nov 28 19:52:19 malloc kernel: in: IN=eth1 OUT= MAC= SRC=192.168.1.31 DST=192.168.0.54 LEN=100 TOS=0x00 PREC=0x00 TTL=63 ID=38565 DF PROTO=TCP SPT=25 DPT=1071 WINDOW=57352 RES=0x00 ACK PSH URGP=0 
    mac: ~
    out_int: ~
    ip:
      dst_addr: 192.168.0.54
      fragment_flags:
        - DF
      id: 38565
      len: 100
      prec: 0x00
      src_addr: 192.168.1.31
      tos: 0x00
      ttl: 63
      type: tcp
      tcp:
        dst_port: 1071
        flags:
          - ACK
          - PSH
        res: 0x00
        src_port: 25
        urgp: 0
        window: 57352

=head2 UDP packet

    in_int: eth1
    leftover: ~
    line: >-
      Nov 29 10:52:11 malloc kernel: in: IN=eth1 OUT= MAC= SRC=10.9.8.46 DST=192.168.0.208 LEN=801 TOS=0x00 PREC=0x00 TTL=115 ID=3391 PROTO=UDP SPT=31466 DPT=1026 LEN=781 
    mac: ~
    out_int: ~
    ip:
      dst_addr: 192.168.0.208
      id: 3391
      len: 801
      prec: 0x00
      src_addr: 10.9.8.46
      tos: 0x00
      ttl: 115
      type: udp
      udp:
        dst_port: 1026
        len: 781
        src_port: 31466

=head2 ICMP echo packet

    in_int: ppp0
    leftover: ~
    line: >-
      Nov 30 09:54:51 malloc kernel: in: IN=ppp0 OUT= MAC= SRC=10.0.0.34 DST=192.168.143.41 LEN=37 TOS=0x00 PREC=0x00 TTL=115 ID=61772 PROTO=ICMP TYPE=8 CODE=0 ID=256 SEQ=8403 
    mac: ~
    out_int: ~
    ip:
      dst_addr: 192.168.143.41
      id: 61772
      len: 37
      prec: 0x00
      src_addr: 10.0.0.34
      tos: 0x00
      ttl: 115
      type: icmp
      icmp:
        code: 0
        id: 256
        seq: 8403
        type: 8

=head2 ICMP error packet

    in_int: ppp0
    leftover: ~
    line: >-
      Nov 28 11:17:33 malloc kernel: in: IN=ppp0 OUT= MAC= SRC=192.168.2.113 DST=192.168.0.223 LEN=492 TOS=0x00 PREC=0x00 TTL=240 ID=39184 PROTO=ICMP TYPE=3 CODE=3 [SRC=192.168.0.223 DST=192.168.2.113 LEN=464 TOS=0x00 PREC=0x00 TTL=52 ID=58665 DF PROTO=TCP SPT=34373 DPT=80 WINDOW=63712 RES=0x00 ACK PSH FIN URGP=0 ]
    mac: ~
    out_int: ~>
    ip:
      dst_addr: 192.168.0.223
      id: 39184
      len: 492
      prec: 0x00
      src_addr: 192.168.2.113
      tos: 0x00
      ttl: 240
      type: icmp
      icmp:
        code: 3
        type: 3
        error_header:
          leftover: ~
          line: >-
            SRC=192.168.0.223 DST=192.168.2.113 LEN=464 TOS=0x00 PREC=0x00 TTL=52 ID=58665 DF PROTO=TCP SPT=34373 DPT=80 WINDOW=63712 RES=0x00 ACK PSH FIN URGP=0
          ip:
            dst_addr: 192.168.2.113
            fragment_flags:
              - DF
            id: 58665
            len: 464
            prec: 0x00
            src_addr: 192.168.0.223
            tos: 0x00
            ttl: 52
            type: tcp
            tcp:
              dst_port: 80
              flags:
                - ACK
                - PSH
                - FIN
              res: 0x00
              src_port: 34373
              urgp: 0
              window: 63712
        
=head1 SEE ALSO

POE::Filter.

=head1 BUGS

There are probably some corner cases that this module can't parse
correctly. I haven't tested, in particular, AH, ESP, other
non-tcp/udp/icmp protocols, ICMP packets of type 11 (parameter problem),
5 (redirect), and 4 (source quench). It also has some problems with logs
from bridging firewalls. I haven't tested ebtables logs at all.

It doesn't even pretend to support IPv6. It shouldn't be too hard to do,
but I don't have any IPv6 networks to test with. All the code is in
/usr/src/linux/net/ipv6/netfilter/ip6t_LOG.c, though. Patches welcome.

Doesn't support --log-tcp-sequence, --log-tcp-options, or
--log-ip-options. It won't throw the whole line out, though, it'll do
the best it can and hand you the leftovers in the 'leftover' field of
the hashref.

Doesn't support get_one(), get_one_start(), or get_pending(). This means
switching from this filter to another filter probably won't work, but I
haven't tried it.

Doesn't support put(), though it would be cool to be able to take
iptables logs and write the iptables commands used to generate them.

=head1 AUTHOR

Paul Visscher, E<lt>paulv@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2005 by Paul Visscher

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
