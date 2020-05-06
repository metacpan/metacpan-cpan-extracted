#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IO::Async::Loop;
use IO::Async::Test;

use IO::Socket::INET;
use Net::Async::ArtNet;

my $loop = IO::Async::Loop->new;
testing_loop( $loop );

my @dmx;
my $artnet = Net::Async::ArtNet->new(
   port => 0, # kernel-allocated
   on_dmx => sub {
      my $self = shift;
      my ( $seq, $phy, $uni, $data ) = @_;
      @dmx = @$data;
   },
);
$loop->add( $artnet );

my $xmit = IO::Socket::INET->new(
   PeerHost => "127.0.0.1",
   PeerPort => $artnet->read_handle->sockport,
   Proto    => "udp",
);

$xmit->send(
   # MAGIC       Opcode       Version
   "Art-Net\0" . "\x00\x50" . "\x00\x0E" .
   # Seq    Phy      Uni      Net
   "\x00" . "\x00" . "\x00" . "\x00" .
   # Length     Data
   "\x00\x04" . "\x01\x23\x45\x67"
);

wait_for { scalar @dmx };
is_deeply( \@dmx, [ 1, 35, 69, 103 ],
   'DMX data received'
);

done_testing;
