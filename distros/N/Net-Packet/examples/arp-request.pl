#!/usr/bin/perl
#
# $Id: arp-request.pl 1640 2009-11-09 17:58:27Z gomor $
#
use strict;
use warnings;

use Getopt::Std;
my %opts;
getopts('i:I:M:d:vt', \%opts);

die "Usage: $0 -i dstIp [-I srcIp] [-M srcMac] [-d device] ".
    "[-v] [-t timeout]\n"
   unless $opts{i};

use Net::Packet;

$Env->dev($opts{d}) if $opts{d};
$Env->ip ($opts{I}) if $opts{I};
$Env->mac($opts{M}) if $opts{M};
$Env->debug(3)      if $opts{v};

my $eth = Net::Packet::ETH->new(
   type => NP_ETH_TYPE_ARP,
);

my $arp = Net::Packet::ARP->new(
   opCode => NP_ARP_OPCODE_REQUEST,
   dstIp  => $opts{i},
);

my $frame = Net::Packet::Frame->new(l2 => $eth, l3 => $arp);

print "Request:\n";
print $frame->print, "\n";
$frame->send;

until ($Env->dump->timeout) {
   if ($frame->recv) {
      print "\nReply:\n";
      print $frame->reply->l2->print, "\n";
      print $frame->reply->l3->print, "\n";
      print "padding: ", unpack('H*', $frame->reply->padding), "\n";
      print "\n", $frame->reply->l3->srcIp, " is-at ", $frame->reply->l3->src,
            "\n";
      last;
   }
}

$Env->dump->stop;
$Env->dump->clean;
