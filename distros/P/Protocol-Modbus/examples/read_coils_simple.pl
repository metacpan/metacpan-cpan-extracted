#!/usr/bin/env perl

#
# Modbus/TCP Server query
#
# Issues a read coils request on an IP address / port
# Here Protocol::Modbus is used only to build request
#
# Cosimo  Feb 1st, 2007
#

use strict;
use warnings;
use Protocol::Modbus;

$| = 1;

my $modbus = Protocol::Modbus->new(driver=>'TCP');

# with explicit method name
my $req = $modbus->readCoilsRequest(
    address  => 0,
    quantity => 64,
    unit     => 1,
);

# Open a socket to device
use IO::Socket::INET;
my $ip = '192.168.11.99';
my $sock = IO::Socket::INET->new(
    PeerAddr => $ip,
    PeerPort => 502,
    Timeout  => 3,
);

die "Can't connect\n" unless $sock;

print "Connected.\n";

while(1)
{
    $sock->send($req->pdu());
    select(undef, undef, undef, 0.2);
    $sock->recv(my $sock_data, 100);
    #diag('Received: [' . unpack('H*', $sock_data) . ']');
    print 'Received: [' . unpack('H*', $sock_data) . ']' . "\r";
    select(undef, undef, undef, 0.5);
}

