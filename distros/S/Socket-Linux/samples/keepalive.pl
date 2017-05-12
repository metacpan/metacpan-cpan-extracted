#!/usr/bin/perl

use strict;
use warnings;

use Socket qw(IPPROTO_TCP SOL_SOCKET PF_INET SOCK_STREAM SO_KEEPALIVE inet_aton sockaddr_in);
use Socket::Linux qw(TCP_NODELAY TCP_KEEPIDLE TCP_KEEPINTVL TCP_KEEPCNT);
use autodie;

my $host = shift // die "hostname missing";
my $port = shift // die "port missing";


my $sin = sockaddr_in($port, inet_aton($host));
socket my $sock, PF_INET, SOCK_STREAM, getprotobyname('tcp');

setsockopt($sock, IPPROTO_TCP, TCP_NODELAY,    1);
setsockopt($sock, SOL_SOCKET,  SO_KEEPALIVE,   1);
setsockopt($sock, IPPROTO_TCP, TCP_KEEPIDLE,  10);
setsockopt($sock, IPPROTO_TCP, TCP_KEEPINTVL,  5);
setsockopt($sock, IPPROTO_TCP, TCP_KEEPCNT,    3);

connect($sock, $sin);

while (<$sock>) {
    print;
}

print "*** connection closed!\n";
