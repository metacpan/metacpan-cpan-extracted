#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use IO::Async::Loop;
use IO::Async::Test;

use IO::Socket::INET;
use Net::Async::ArtNet;

my $loop = IO::Async::Loop->new;
testing_loop( $loop );

my @dmx;
my $artnet = Net::Async::ArtNet->new(
   family => "inet", # Force IPv4 so we can use 127.0.0.1 to test on
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
is( \@dmx, [ 1, 35, 69, 103 ],
   'DMX data received'
);

done_testing;
