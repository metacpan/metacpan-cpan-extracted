#!/usr/bin/perl
#
# $Id: arp-reply.pl 1640 2009-11-09 17:58:27Z gomor $
#
use strict;
use warnings;

use Getopt::Std;
my %opts;
getopts('m:M:i:a:d:v', \%opts);

die "Usage: $0 -i dstIp -a isAtMac [-M srcMac] [-m dstMac] ".
    "(or will broadcast) [-d device] [-v]\n"
   unless $opts{i} && $opts{a};

use Net::Packet;

$Env->dev($opts{d}) if $opts{d};
$Env->mac($opts{M}) if $opts{M};
$Env->debug(3)      if $opts{v};
$Env->noFrameAutoDump(1);

my $eth = Net::Packet::ETH->new(
   type => NP_ETH_TYPE_ARP,
);
$eth->dst($opts{m}) if $opts{m};

my $arp = Net::Packet::ARP->new(
   opCode => NP_ARP_OPCODE_REPLY,
   src    => $opts{a},
   srcIp  => $opts{i},
   dstIp  => $opts{i},
);
$arp->dst($opts{m}) if $opts{m};

my $frame = Net::Packet::Frame->new(l2 => $eth, l3 => $arp);

print "Sending:\n";
print $frame->l2->print, "\n";
print $frame->l3->print, "\n";

$frame->send;
