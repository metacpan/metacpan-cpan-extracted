#!/usr/bin/perl
# Simple DHCP client - send a LeaseQuery (by IP) and receive the response

use IO::Socket::INET;
use Net::DHCP::Packet;
use Net::DHCP::Constants;

$usage = "usage: $0 DHCP_SERVER_IP DHCP_CLIENT_IP\n"; $ARGV[1] || die $usage;

# create a socket
$handle = IO::Socket::INET->new(Proto => 'udp',
                                Broadcast => 1,
                                PeerPort => '67',
                                LocalPort => '67',
                                PeerAddr => $ARGV[0])
              or die "socket: $@";     # yes, it uses $@ here

# create DHCP Packet
$inform = Net::DHCP::Packet->new(
                    op => BOOTREQUEST(),
                    Htype  => '0',
                    Hlen   => '0',
                    Ciaddr => $ARGV[1],
                    Giaddr => $handle->sockhost(),
                    Xid => int(rand(0xFFFFFFFF)),     # random xid
                    DHO_DHCP_MESSAGE_TYPE() => DHCPLEASEQUERY
                    );

# send request
$handle->send($inform->serialize()) or die "Error sending LeaseQuery: $!\n";

#receive response
$handle->recv($newmsg, 1024) or die;
$packet = Net::DHCP::Packet->new($newmsg);
print $packet->toString();
