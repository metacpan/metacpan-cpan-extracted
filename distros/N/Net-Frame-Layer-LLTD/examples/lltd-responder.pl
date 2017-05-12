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
use Net::Frame::Layer::LLTD::Tlv;

my $d = Net::Frame::Device->new(dev => $dev);

my $p = Net::Frame::Dump::Online->new(
   dev    => $d->dev,
   filter => 'not ip and not arp and not ip6',
   onRecv => \&sendHello,
);

my $generationNumber;
my $mapperAddress;
my $identifier;

$p->start;

sub sendData {
   my ($d, $data, $count) = @_;

   my $w = Net::Write::Layer2->new(dev => $d->dev);
   $w->open;
   $count ? do { $w->send($data) for 1..$count }
          : do { $w->send($data) for 1..3      };
   $w->close;
}

sub sendHello {
   my ($h, $data) = @_;

   my $frame = Net::Frame::Simple->newFromDump($h);

   my $eth  = $frame->ref->{ETH};
   my $lltd = $frame->ref->{LLTD};

   # First step, for discovery process, send Hello
   if ($eth && $eth->src ne $d->mac && $lltd && $lltd->upperLayer) {
      if ($lltd->function == NF_LLTD_FUNCTION_HELLO
      &&  $lltd->upperLayer->generationNumber > 0) {
         print "Received discover\n";

         my $eth = Net::Frame::Layer::ETH->new(
            src  => $d->mac,
            dst  => NF_ETH_ADDR_BROADCAST,
            type => NF_ETH_TYPE_LLTD,
         );

         $generationNumber = $lltd->upperLayer->generationNumber
            unless $generationNumber;
         $mapperAddress = $lltd->upperLayer->currentMapperAddress
            unless $mapperAddress;

         my $hello = buildHello($d, $eth, $generationNumber, $mapperAddress);
         #print $hello->print."\n";

         sendData($d, $hello->raw."\x00");
      }
      # After Hello, discoverer will send stationList
      elsif ($lltd->function == NF_LLTD_FUNCTION_DISCOVER
         &&  $lltd->upperLayer->generationNumber == ($generationNumber+1)
         &&  $lltd->upperLayer->numberOfStations > 0) {
         for ($lltd->upperLayer->stationList) {
            print "station: $_\n";
         }
      }
      # Then Emit
      elsif ($lltd->function == NF_LLTD_FUNCTION_EMIT
         &&  $lltd->upperLayer->numDescs > 0
         &&  $eth->dst eq $d->mac) {
         print "*** Ready for second step\n";
         print $eth->print."\n";
         print $lltd->print."\n";

         $identifier = $lltd->identifier
            unless $identifier;

         my $eth = Net::Frame::Layer::ETH->new(
            src  => $d->mac,
            dst  => $mapperAddress,
            type => NF_ETH_TYPE_LLTD,
         );

         my $lltdResp = Net::Frame::Layer::LLTD->new(
            version         => 1,
            tos             => 0x00,
            reserved        => 0,
            function        => 0x05,
            networkAddress1 => $mapperAddress,
            networkAddress2 => $d->mac,
            #identifier      => $identifier,
            identifier      => 13001,
         );
         #print "*** $identifier\n";

         my $reply = Net::Frame::Simple->new(layers => [ $eth, $lltdResp ]);
         #print $reply->print."\n";
         sendData($d, $reply->raw, 1);
      }
      elsif ($lltd->function == NF_LLTD_FUNCTION_EMIT && $eth->dst eq $d->mac) {
         print "*** ".$eth->print."\n";
         print "*** ".$lltd->print."\n";
      }
   }
}

END { $p && $p->isRunning && $p->stop }

#
# Subs
#
sub buildHello {
   my ($d, $eth, $id, $mapperAddress) = @_;

   my $lltdHello = Net::Frame::Layer::LLTD->new(
      version         => 1,
      tos             => NF_LLTD_TOS_QUICK_DISCOVERY,
      reserved        => 0,
      function        => NF_LLTD_FUNCTION_HELLO,
      networkAddress1 => 'ff:ff:ff:ff:ff:ff',
      networkAddress2 => $d->mac,
      identifier      => 0,
   );
   my $hello = Net::Frame::Layer::LLTD::Hello->new(
      generationNumber      => $id,
      currentMapperAddress  => $mapperAddress,
      apparentMapperAddress => $mapperAddress,
   );
   $lltdHello->upperLayer($hello);

   (my $mac = $d->mac) =~ s/://g;
   my $tlvMac = Net::Frame::Layer::LLTD::Tlv->new(
      type   => 0x01,
      length => 6,
      value  => pack('H12', $mac),
   );

   my $tlvIp = Net::Frame::Layer::LLTD::Tlv->new(
      type   => NF_LLTD_TLV_TYPE_IPv4ADDRESS,
      length => 4,
      value  => inetAton($d->ip),
   );

   my $tlvName = Net::Frame::Layer::LLTD::Tlv->new(
      type   => NF_LLTD_TLV_TYPE_MACHINENAME,
      length => 8,
      value  => pack('a*', "A\0A\0A\0A\0"),
   );

   $hello->tlvList([ $tlvMac, $tlvIp, $tlvName ]);

   Net::Frame::Simple->new(
      layers => [ $eth, $lltdHello ],
   );
}

sub buildAck {
   my ($d, $mapperAddress) = @_;

}
