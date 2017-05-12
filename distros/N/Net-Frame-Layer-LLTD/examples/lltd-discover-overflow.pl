#!/usr/bin/perl
use strict;
use warnings;

my $dev = shift || die("Specify network interface\n");

use Net::Frame::Device;
use Net::Write::Layer2;
use Net::Frame::Dump::Online;

use Net::Frame::Layer qw(:subs);
use Net::Frame::Layer::ETH qw(:consts);
use Net::Frame::Layer::LLTD qw(:consts);
use Net::Frame::Layer::LLTD::Discover;

my $d = Net::Frame::Device->new(dev => $dev);

my $eth = Net::Frame::Layer::ETH->new(
   src  => $d->mac,
   dst  => NF_ETH_ADDR_BROADCAST,
   type => NF_ETH_TYPE_LLTD,
);

my $id = getRandom16bitsInt();

my $reset = buildReset   ($d, $eth,   0);
my $disco = buildDiscover($d, $eth, $id);
my $hello = buildHello   ($d, $eth,   0);

my $p = Net::Frame::Dump::Online->new(
   dev    => $d->dev,
   filter => 'not ip and not arp and not ip6',
);
$p->start;

my $w = Net::Write::Layer2->new(dev => $d->dev);
$w->open;

#$w->send($reset->raw) for 1..3;
#$w->send($disco->raw) for 1..3;
$w->send($hello->raw) for 1..3;

my $hosts;
until ($p->timeout) {
   if (my $h = $p->next) {
      my $frame = Net::Frame::Simple->newFromDump($h);
      if ($frame->ref->{ETH} && $frame->ref->{LLTD}) {
         my $eth  = $frame->ref->{ETH};
         my $lltd = $frame->ref->{LLTD};
         if ($lltd->upperLayer && $lltd->function == NF_LLTD_FUNCTION_HELLO
         &&  $lltd->upperLayer->tlvList) {
            print "Host found\n";
            my $mac;
            my $ip;
            for ($lltd->upperLayer->tlvList) {
               if ($_->type == 0x01) {
                  $mac = convertMac(unpack('H12', $_->value));
               }
               elsif ($_->type == 0x07) {
                  $ip = inetNtoa($_->value);
               }
            }
            if ($mac && $ip) {
               $hosts->{$mac} = $ip;
            }
         }
      }
   }
}

$w->close;
$p->stop;

for (keys %$hosts) {
   print "$_ => ".$hosts->{$_}."\n";
}

#
# Subs
#
sub buildReset {
   my ($d, $eth, $id) = @_;

   my $lltdReset = Net::Frame::Layer::LLTD->new(
      version         => 1,
      tos             => NF_LLTD_TOS_TOPOLOGY_DISCOVERY,
      reserved        => 0,
      function        => NF_LLTD_FUNCTION_RESET,
      networkAddress1 => 'ff:ff:ff:ff:ff:ff',
      networkAddress2 => $d->mac,
      identifier      => $id,
   );

   Net::Frame::Simple->new(
      layers => [ $eth, $lltdReset ],
   );
}

sub buildDiscover {
   my ($d, $eth, $id) = @_;

   my $lltdDiscover = Net::Frame::Layer::LLTD->new(
      version         => 1,
      tos             => NF_LLTD_TOS_TOPOLOGY_DISCOVERY,
      reserved        => 0,
      function        => NF_LLTD_FUNCTION_DISCOVER,
      networkAddress1 => 'ff:ff:ff:ff:ff:ff',
      networkAddress2 => $d->mac,
      identifier      => $id,
   );
   my $discover = Net::Frame::Layer::LLTD::Discover->new(
      generationNumber => 0,
      numberOfStations => 0,
   );
   $lltdDiscover->upperLayer($discover);

   Net::Frame::Simple->new(
      layers => [ $eth, $lltdDiscover ],
   );
}

sub buildHello {
   my ($d, $eth, $id) = @_;

   my $lltdHello = Net::Frame::Layer::LLTD->new(
      version         => 1,
      tos             => NF_LLTD_TOS_QUICK_DISCOVERY,
      reserved        => 0,
      function        => NF_LLTD_FUNCTION_HELLO,
      networkAddress1 => 'ff:ff:ff:ff:ff:ff',
      networkAddress2 => $d->mac,
      identifier      => $id,
   );
   my $hello = Net::Frame::Layer::LLTD::Hello->new(
      generationNumber      => 0,
      currentMapperAddress  => $d->mac,
      apparentMapperAddress => $d->mac,
   );
   $lltdHello->upperLayer($hello);

   my @tlvList;
   for (1..5) {
      my $tlv = Net::Frame::Layer::LLTD::Tlv->new(
         #type   => NF_LLTD_TLV_TYPE_MACHINENAME,
         type   => 0xff,
         length => 255,
         value  => "A"x255,
      );
      push @tlvList, $tlv;
   }
   $hello->tlvList(\@tlvList);

   Net::Frame::Simple->new(
      layers => [ $eth, $lltdHello ],
   );
}
