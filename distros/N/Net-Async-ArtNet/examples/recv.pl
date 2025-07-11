#!/usr/bin/perl

use v5.14;
use warnings;

use IO::Async::Loop;
use Net::Async::ArtNet;

my $loop = IO::Async::Loop->new;

$loop->add( Net::Async::ArtNet->new(
   on_dmx => sub {
      my $self = shift;
      my ( $seq, $phy, $universe, $data ) = @_;

      return unless $phy == 0 and $universe == 0;

      my $ch10 = $data->[10 - 1];  # DMX channels are 1-indexed
      print "Channel 10 now set to: $ch10\n";
   }
) );

$loop->run;
