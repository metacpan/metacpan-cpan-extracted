#!/usr/bin/perl
use IO::Socket::INET;
use Net::DHCP::Packet;

$sock = IO::Socket::INET->new(LocalPort => 67, Proto => "udp", Broadcast => 1)
        or die "socket: $@";

while ($sock->recv($newmsg, 1024)) {
    $packet = Net::DHCP::Packet->new($newmsg);
    print STDERR $packet->toString();
}
