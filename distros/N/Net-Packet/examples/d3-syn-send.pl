#!/usr/bin/perl
#
# $Id: d3-syn-send.pl 1640 2009-11-09 17:58:27Z gomor $
#
use strict;
use warnings;

use Getopt::Std;
my %opts;
getopts('i:I:p:d:v', \%opts);

die "Usage: $0 -i dstIp -p dstPort [-I srcIp] [-d device] [-v]\n"
   unless $opts{i} && $opts{p};

use Net::Packet;

$Env->dev($opts{d}) if $opts{d};
$Env->ip ($opts{I}) if $opts{I};
$Env->debug(3)      if $opts{v};

my $d4 = Net::Packet::DescL3->new(
   target => $opts{i},
);

my $frame = Net::Packet::Frame->new(
   l3 => Net::Packet::IPv4->new(
      dst => $opts{i},
   ),
   l4 => Net::Packet::TCP->new(
      dst => $opts{p},
   ),
);

$frame->send;

until ($Env->dump->timeout) {
   if ($frame->recv) {
      print "Reply:\n";
      print $frame->reply->l3->print, "\n";
      print $frame->reply->l4->print, "\n";
      last;
   }
}

$Env->dump->stop;
$Env->dump->clean;
