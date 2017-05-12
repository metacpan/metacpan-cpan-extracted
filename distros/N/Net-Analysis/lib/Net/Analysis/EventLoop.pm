package Net::Analysis::EventLoop;
# $Id: EventLoop.pm 131 2005-10-02 17:24:31Z abworrall $

use 5.008000;
our $VERSION = '0.01';
use strict;
use warnings;

use Carp qw(carp croak confess);

use NetPacket::Ethernet qw(:ALL);
use NetPacket::IP       qw(:ALL);
use NetPacket::TCP      qw(:ALL);
use NetPacket::UDP      qw(:ALL);
use Net::Pcap;
use Params::Validate qw(:all);

use Net::Analysis::Packet qw(:all);

#### Public methods
#
# {{{ new

sub new {
    my ($class) = shift;
    my ($self)  = bless ({pkt_number => 0}, $class);

    my %h = validate (@_, {dispatcher => { can => 'emit_event' }});

    $self->{dispatcher} = $h{dispatcher};

    return $self;
}

# }}}

# {{{ loop_file

sub loop_file {
    my ($self) = shift;
    my %h = validate (@_, { filename  => { type => SCALAR },
                            no_setup_teardown => { type => SCALAR,
                                                   default => 0} });

    my ($np_err);
    my ($pcap_t) = Net::Pcap::open_offline ($h{filename}, \$np_err);

    carp "event_loop('$h{filename}') failed: '$np_err'\n" if (defined $np_err);
    $self->_event_loop ($pcap_t, $h{no_setup_teardown});
}

# }}}
# {{{ loop_net

sub loop_net {
    my ($self) = shift;
    my %h = validate (@_, { filter  => { type => SCALAR } });

    # See 'man Net::Pcap' for more details on these settings.
    my $promiscuity     = 0;
    my $snaplen         = 10240; # Must be >1540, else we will miss bytes
    my $timeout_ms      = 0;
    my $optimize_filter = 1;

    my ($np_err, $net, $mask, $filter_t);

    my $dev = Net::Pcap::lookupdev(\$np_err);
    Net::Pcap::lookupnet ($dev, \$net, \$mask, \$np_err);

    my $pcap_t = Net::Pcap::open_live($dev, $snaplen, $promiscuity,
                                      $timeout_ms, \$np_err);

    if (defined $np_err) {
        carp "loop_net(filter=>'$h{filter}') failed: '$np_err'\n";
    }

    if (Net::Pcap::compile ($pcap_t, \$filter_t, $h{filter},
                            $optimize_filter, $net) == -1)
    {
        carp "unable to compile filter string '$h{filter}'\n";
    }

    Net::Pcap::setfilter ($pcap_t, $filter_t);
    $self->_event_loop ($pcap_t);
}

# }}}

# {{{ summary

sub summary {
    my ($self) = @_;

    print "---{ parse summary }---\n";
    foreach (sort {$self->{n_pkts}{$b} <=> $self->{n_pkts}{$a}} keys %{$self->{n_pkts}})
    {
          printf "  %-40.40s: % 7d\n", $_, $self->{n_pkts}{$_};
    }
}

# }}}


#### Private helper methods
#

# {{{ _netpacket_packet_to_our_packet

sub _netpacket_packet_to_our_packet {
    my ($self, $wire_pkt, $wire_hdrs) = @_;

    # We assume ethernet capture ...
    my ($eth_obj) = NetPacket::Ethernet->decode ($wire_pkt);

    # A flexible OO dispatch scheme is probably where this is heading ...

    if ($eth_obj->{type} == ETH_TYPE_IP) {
        my $ip_obj = NetPacket::IP->decode($eth_obj->{data});

        if($ip_obj->{proto} == IP_PROTO_TCP) {
            # Some ethernet frames come with padding; this confuses NetPacket,
            #  so strip it off here before parsing the IP payload as a TCP
            #  packet.
            my $ip_data_len = $ip_obj->{len} - $ip_obj->{hlen} * 4;
            if ($ip_data_len < length($ip_obj->{data})) {
                substr ($ip_obj->{data}, $ip_data_len) = '';
            }

            my $tcp_obj = NetPacket::TCP->decode ($ip_obj->{data});
            #$self->{n_pkts}{"tcp_ok"}++;
            # $ip_obj has the IP addresses
            # $tcp_obj has the ports & TCP info, and the payload in {data}

            # Create a 'vendor-neutral' packet, in case we leave NetPacket
            my $pkt = ["$ip_obj->{dest_ip}:$tcp_obj->{dest_port}",
                       "$ip_obj->{src_ip}:$tcp_obj->{src_port}",
                       $tcp_obj->{flags},
                       $tcp_obj->{data},
                       $tcp_obj->{seqnum},
                       $tcp_obj->{acknum},
                       $self->{pkt_number}++,
                       # These are turned into the object $pkt->{time}
                       $wire_hdrs->{tv_sec},
                       $wire_hdrs->{tv_usec},
                      ];
            pkt_init($pkt);

            return $pkt;

=pod

            return Net::Analysis::Packet->new
              ({to    => "$ip_obj->{dest_ip}:$tcp_obj->{dest_port}",
                from  => "$ip_obj->{src_ip}:$tcp_obj->{src_port}",
                flags => $tcp_obj->{flags},
                data  => $tcp_obj->{data},
                seqnum => $tcp_obj->{seqnum},
                acknum => $tcp_obj->{acknum},
                pkt_number => $self->{pkt_number}++,

                # These are turned into the object $pkt->{time}
                tv_sec  => $wire_hdrs->{tv_sec},
                tv_usec => $wire_hdrs->{tv_usec},
               } );

=cut

        #} elsif ($ip_obj->{proto} == IP_PROTO_UDP) {
            # We should handle these at some point ...
            #$self->{n_pkts}{"SKIP_ip_proto_UDP"}++;
        #} else {
            #$self->{n_pkts}{"SKIP_ip_proto_$ip_obj->{proto}"}++;
        }

    #} else {
        # ARP ? AppleTalk ? SNMP ? IPv6 ? PPP ? Whatever, skip it
        #$self->{n_pkts}{"SKIP_eth_pkt_type_$eth_obj->{type}"}++;
    }

    return undef;
}

# }}}
# {{{ _event_loop

sub _event_loop {
    my ($self, $pcap_t, $no_setup_teardown) = @_;

    unless ($no_setup_teardown) {
        $self->{dispatcher}->emit_event (name => 'setup');
    }

    while (1) {
        my (%hdr);
        my ($np_pkt) = Net::Pcap::next($pcap_t, \%hdr);
        last if (!defined $np_pkt);

        if ($hdr{len} != $hdr{caplen}) {
            warn "incomplete packet - use tcpdump with option '-S 2048'\n";
            next;
        }

        my $our_pkt = $self->_netpacket_packet_to_our_packet ($np_pkt, \%hdr);

        next if (!defined $our_pkt);

        # This will need re-jigging when we handle more than just TCP
        $self->{dispatcher}->emit_event (name => '_internal_tcp_packet',
                                         args => {pkt => $our_pkt});
    }

    unless ($no_setup_teardown) {
        $self->{dispatcher}->emit_event (name => 'teardown');
    }
}

# }}}


1;
__END__
# {{{ POD

=head1 NAME

Net::Analysis::EventLoop - generate a stream of packets

=head1 SYNOPSIS

 use Net::Analysis::Dispatcher;
 use Net::Analysis::EventLoop;

 my ($d)  = Net::Analysis::Dispatcher->new();
 my ($el) = Net::Analysis::EventLoop->new (dispatcher => $d);

 ... register some listener modules onto the dispatcher ...

 # Now run it over a file ...
 $el->loop_file (filename => 'some.tpcdump');

 # ... or run it over many files ...
 $d->emit_event (name => 'setup'); # need to handle setup/teardown by hand
 foreach (qw(file1 file2 ...)) {
   $el->loop_file (filename => $_, no_setup_teardown => 1);
 }
 $d->emit_event (name => 'teardown');

 # ... or try live capture (using the same filter syntax as tcpdump et al)
 $el->loop_net (filter => 'port 80');

 exit 0;

=head1 DESCRIPTION

This module provides the glue between the main dispatcher/listener stuff, and
the underlying source of packets.

It gets packets (currently via the NetPacket layer on top of Net::Pcap), turns
them into L<Net::Analysis::Packet>s, and then dispatches them to any listeners
who care about 'tcp_packets'.

Current limitations:

=over 4

=item *

Only TCP packets are handled

=item *

It's not designed to be fast; don't run on GB files unless you're about to go
home. Live capture on busy servers may not be the best either; make the most
specific filter you can, to allow Net::Pcap to reduce the number of packets
that get to here. And watch your memory; it's likely to leak.

=item *

Live capture is not perfectly integrated; there is no way to cleanly stop
capture at this time.

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

Net::Analysis::Dispatcher

=head1 AUTHOR

Adam B. Worrall, E<lt>worrall@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Adam B. Worrall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut

# }}}

# {{{ -------------------------={ E N D }=----------------------------------

# Local variables:
# folded-file: t
# end:

# }}}
