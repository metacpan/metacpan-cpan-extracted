#!/usr/bin/env perl

use strict;
use warnings;
use Carp;

use IO::Socket;

my $socket;

my $port  = $ARGV[0];
my $sleep = $ARGV[1];

my $host = '127.0.0.1';

$socket = IO::Socket::INET->new(
    Proto    => 'tcp',
    PeerAddr => $host,
    PeerPort => $port,
    Timeout  => 1,
    Blocking => 0,
) or croak "Cannot connect to $host $port";

sleep $sleep;
$socket->send("\x00");
sleep $sleep;

# enquire_link packet:
my $packet = "\x00\x00\x00\x10"
           . "\x00\x00\x00\x15"
           . "\x00\x00\x00\x00"
           . "\x00\x00\x00\x02"
;
$socket->send($packet);
sleep $sleep;

$socket->close();

