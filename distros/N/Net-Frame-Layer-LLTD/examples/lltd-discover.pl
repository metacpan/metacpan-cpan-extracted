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
use Net::Frame::Layer::LLTD::Tlv;

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

$reset->send($w) for 1..3;
$disco->send($w) for 1..3;
$hello->send($w);

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
            my ($mac, $ip, $name, $ip6, $perfCounter, $linkSpeed);
            for ($lltd->upperLayer->tlvList) {
               if ($_->type == NF_LLTD_TLV_TYPE_HOSTID) {
                  $mac = convertMac(unpack('H12', $_->value));
               }
               elsif ($_->type == NF_LLTD_TLV_TYPE_IPv4ADDRESS) {
                  $ip = inetNtoa($_->value);
               }
               elsif ($_->type == NF_LLTD_TLV_TYPE_IPv6ADDRESS) {
                  $ip6 = inet6Ntoa($_->value);
               }
               #elsif ($_->type == NF_LLTD_TLV_TYPE_PERFCOUNTER) {
                  #$perfCounter = unpack('N', $_->value << 32);
               #}
               elsif ($_->type == NF_LLTD_TLV_TYPE_MACHINENAME) {
                  $name = $_->value;
               }
               elsif ($_->type == NF_LLTD_TLV_TYPE_LINKSPEED) {
                  $linkSpeed = unpack('N', $_->value);
               }
            }
            if ($mac && ($ip || $ip6) && not exists $hosts->{$mac}) {
               push @{$hosts->{$mac}}, $ip;
               push @{$hosts->{$mac}}, $name        if $name;
               push @{$hosts->{$mac}}, $ip6         if $ip6;
               push @{$hosts->{$mac}}, $perfCounter if $perfCounter;
               push @{$hosts->{$mac}}, $linkSpeed   if $linkSpeed;
            }
         }
      }
   }
}

$reset->send($w) for 1..3;

$w->close;
$p->stop;

use Data::Dumper;
print Dumper($hosts)."\n";

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
      generationNumber => 0,
      currentMapperAddress  => $d->mac,
      apparentMapperAddress => $d->mac,
   );
   $lltdHello->upperLayer($hello);

   #my $tlv = Net::Frame::Layer::LLTD::Tlv->new(
      #type   => 0x01,
      #length => 6,
      #value  => pack('H12', 'ffffffffffff'),
   #);
   #$hello->tlvList([ $tlv ]);

   Net::Frame::Simple->new(
      layers => [ $eth, $lltdHello ],
   );
}
