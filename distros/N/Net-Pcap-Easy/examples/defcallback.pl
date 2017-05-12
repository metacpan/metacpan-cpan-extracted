#!/usr/bin/perl

use strict;
use warnings;
use Net::Pcap::Easy;

# all arguments to new are optoinal
my $npe = Net::Pcap::Easy->new(
    dev              => "lo",
    filter           => "host 127.0.0.1 and icmp",
    packets_per_loop => 10,
    bytes_to_capture => 1024,
    timeout_in_ms    => 0, # 0ms means forever
    promiscuous      => 0, # true or false

    icmp_callback => sub {
        my ($npe, $ether, $ip, $icmp) = @_;

        print "ICMP: $ether->{src_mac}:$ip->{src_ip} -> $ether->{dest_mac}:$ip->{dest_ip}\n";
    },

    default_callback => sub {
        my ($npe, $ether, $po, $spo) = @_;

        if( $po ) {
            if( $po->isa("NetPacket::IP") ) {
                if( $spo ) {
                    if( $spo->isa("NetPacket::TCP") ) {
                        print "TCP packet: $po->{src_ip}:$spo->{src_port} -> ",
                            "$po->{dest_ip}:$spo->{dest_port}\n";

                    } elsif( $spo->isa("NetPacket::UDP") ) {
                        print "UDP packet: $po->{src_ip}:$spo->{src_port} -> ",
                            "$po->{dest_ip}:$spo->{dest_port}\n";

                    } else {
                        print "", ref($spo), ": $po->{src_ip} -> ",
                            "$po->{dest_ip} ($po->{type})\n";
                    }

                } else {
                    print "IP packet: $po->{src_ip} -> $po->{dest_ip}\n";
                }

            } elsif( $po->isa("NetPacket::ARP") ) {
                print "ARP packet: $po->{sha} -> $po->{tha}\n";
            }

        } else {
            print "IPv6 or appletalk or something... huh\n";
        }
    }

);

1 while $npe->loop;

