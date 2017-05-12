#! /usr/bin/perl
use strict;
use warnings;
use IO::Socket::INET;

while (1) {
    my $sock = IO::Socket::INET->new(
        PeerHost => '192.168.1.17',
        PeerPort => 90000,
        Proto    => 'tcp',
    ) or die 'can not connect admin port.';

    my $status = $sock->getline;
    print $status, "\n";
    $sock->close;

    sleep(1);
}

