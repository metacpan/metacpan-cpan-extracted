#!/usr/bin/perl
use strict;
use warnings;

use Net::Frame::Layer qw(:subs);

my $target = shift || die("Specify target IPv6 address\n");
my $dev    = shift;

if ($target) {
   $target = getHostIpv6Addr($target) || die("Unable to revolv hostname\n");
}

use Net::Frame::Device;
use Net::Frame::Simple;
use Net::Frame::Layer::ETH qw(:consts);
use Net::Frame::Layer::IPv6 qw(:consts);
use Net::Frame::Layer::ICMPv6 qw(:consts);
use Net::Frame::Layer::ICMPv6::NeighborSolicitation;

my $oDevice;
if ($dev) {
   $oDevice = Net::Frame::Device->new(target6 => $target, dev => $dev);
}
else {
   $oDevice = Net::Frame::Device->new(target6 => $target);
}

use Net::Frame::Dump::Online;
my $oDump = Net::Frame::Dump::Online->new(
   dev    => $oDevice->dev,
   filter => 'icmp6',
);
$oDump->start;

require Net::IPv6Addr;
my $target6 = Net::IPv6Addr->new($target)->to_string_preferred;
my @dst = split(':', $target6);
my $str = $dst[-2];
$str =~ s/^.*(..)$/$1/;
$target6 = 'ff02::1:ff'.$str.':'.$dst[-1];

#my $str2 = $dst[-1];
#$str2 =~ s/^(..)(..)$/$1:$2/;
#my $mac6 = '33:33:ff:'.$str.':'.$str2;

print $target6."\n";
#print $mac6."\n";

my $eth = Net::Frame::Layer::ETH->new(
   src  => $oDevice->mac,
   #dst  => $mac6,
   type => NF_ETH_TYPE_IPv6,
);

my $ip = Net::Frame::Layer::IPv6->new(
   src        => $oDevice->ip6,
   dst        => $target6,
   nextHeader => NF_IPv6_PROTOCOL_ICMPv6,
);

my $icmp = Net::Frame::Layer::ICMPv6->new(
   type => NF_ICMPv6_TYPE_NEIGHBORSOLICITATION,
);
my $ns = Net::Frame::Layer::ICMPv6::NeighborSolicitation->new(
   targetAddress => $target,
   options       => [
      Net::Frame::Layer::ICMPv6::Option->new(
         type  => NF_ICMPv6_OPTION_SOURCELINKLAYERADDRESS,
         value => pack('H2H2H2H2H2H2', split(':', $oDevice->mac)),
      ),
   ],
);

my $oSimple = Net::Frame::Simple->new(
   layers => [ $eth, $ip, $icmp, $ns, ],
);
print $oSimple->print."\n";

use Net::Write::Layer2;

my $oWrite = Net::Write::Layer2->new(dev => $oDevice->dev);
$oWrite->open;

my $reply;
for (1..3) {
   print 'Try number: '.$_."\n";

   $oWrite->send($oSimple->raw);

   until ($oDump->timeout) {
      if ($reply = $oSimple->recv($oDump)) {
         last;
      }
   }
   last if $reply;
   $oDump->timeoutReset;
}

$oWrite->close;

if ($reply) {
   print 'RECV:'."\n".$reply->print."\n" if $reply;
   for ($reply->ref->{'ICMPv6::NeighborAdvertisement'}->options) {
      if ($_->type eq NF_ICMPv6_OPTION_TARGETLINKLAYERADDRESS) {
         my $mac = unpack('H*', $_->value);
         print convertMac($mac)."\n";
      }
   }
}

END { $oDump && $oDump->isRunning && $oDump->stop }
