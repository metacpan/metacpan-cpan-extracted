#!/usr/bin/env perl

use warnings;
use strict;
use IO::Socket;

my $host = 'localhost';
my $port = 11211;
while(my $arg = shift @ARGV) {
    for ($arg) {
        if (/--host|-h/) { $host = shift @ARGV; }
        elsif (/--port|-p/) { $port = shift @ARGV; }
        else { print "Unknown argument: $arg\n"; }
    }
}

print "Connecting to memcache on $host:$port... ";
my $memsock = IO::Socket::INET->new(
    PeerAddr   => $host,
    PeerPort   => $port,
    Proto       => 'tcp'
);

die "Failed to connect to $host on port $port\n"
    unless $memsock;

print "OK\n";
print $memsock "delete appkit_features\r\n";
print $memsock "delete actiontree\r\n";

my $max   = 2; # number of times to receive DELETED message
my $count = 0;

while(my $data = <$memsock>) {
    $count++;
    chomp $data;
    if ($data !~ /DELETED/) { print "Failed: $data\n"; }
    else { print "OK\n"; }
    last if $count == $max;
}

close $memsock;
