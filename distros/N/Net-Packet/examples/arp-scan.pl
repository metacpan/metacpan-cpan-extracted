#!/usr/bin/perl
#
# $Id: arp-scan.pl 1640 2009-11-09 17:58:27Z gomor $
#
use strict;
use warnings;

use Getopt::Std;
my %opts;
getopts('d:I:M:n:vt:kr:', \%opts);

die "Usage: $0 [-d device] [-I srcIp] [-M srcMac] [-v] ".
    "[-t timeout] [-k] [-r number] -n C.SUB.NET\n"
   unless $opts{n};

die("Invalid C class: $opts{n}\n") unless $opts{n} =~ /^\d+\.\d+\.\d+/;
$opts{n} =~ s/^(\d+\.\d+\.\d+).*$/$1/;

use Net::Packet;

$Env->dev($opts{d}) if $opts{d};
$Env->ip ($opts{I}) if $opts{I};
$Env->mac($opts{M}) if $opts{M};
$Env->debug(3)      if $opts{v};

my @frames;
for (1..254) {
   my $frame = Net::Packet::Frame->new(
      l2 => Net::Packet::ETH->new(type => NP_ETH_TYPE_ARP),
      l3 => Net::Packet::ARP->new(
         opCode => NP_ARP_OPCODE_REQUEST,
         dstIp  => $opts{n}.'.'.$_,
      ),
   );
   push @frames, $frame;
}

$Env->dump->filter("arp and dst host @{[$Env->ip]}");

my $times = $opts{r} ? $opts{r} : 3;
for (1..$times) {
   $_->reSend for @frames;

   sleep($opts{t} ? $opts{t} : 3);

   $Env->dump->nextAll;

   for (@frames) {
      if ($_->recv) {
         print "Reply:\n";
         print $_->reply->l2->print, "\n";
         print $_->reply->l3->print, "\n";
      }
   }
}

do { print $_->reply->l3->srcIp, " => ", $_->reply->l3->src, "\n" if $_->reply }
   for @frames;
