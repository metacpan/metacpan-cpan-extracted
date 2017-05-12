#!/usr/bin/perl
use strict;
use warnings;

use Net::Frame::Layer::OSPF qw(:consts);
use Net::Frame::Layer::OSPF::Hello;
use Net::Frame::Layer::OSPF::DatabaseDesc;
use Net::Frame::Layer::OSPF::Lsa;

# Now, we send the LS Update packet
getOspfLsu('192.168.1.1');

sub getOspfLsu {
   my ($ip) = @_;

   my $lsa = Net::Frame::Layer::OSPF::Lsa->new(
      lsAge             => 1,
      options           => 0x02,
      lsType            => NF_OSPF_LSTYPE_ROUTER,
      linkStateId       => $ip,
      advertisingRouter => $ip,
      lsSequenceNumber  => 0x80000003,
   );

   my $router = Net::Frame::Layer::OSPF::Lsa::Router->new(
      flags    => 0,
      zero     => 0,
      nLink    => 1,
      linkId   => '192.168.1.0',
      linkData => '255.255.255.0',
      type     => 0x03,
      nTos     => 0,
      metric   => 10,
   );

   $lsa->lsa($router);

   $lsa->computeLengths;
   $lsa->computeChecksums;

   print $lsa->print."\n";
}
