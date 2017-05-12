#!/usr/bin/perl
#
# $Id: icmp-information.pl 1640 2009-11-09 17:58:27Z gomor $
#
use strict;
use warnings;

use Getopt::Std;
my %opts;
getopts('i:I:d:v', \%opts);

die "Usage: $0 -i dstIp [-I srcIp] [-d device] [-v]\n"
   unless $opts{i};

use Net::Packet;

$Env->dev($opts{d}) if $opts{d};
$Env->ip ($opts{I}) if $opts{I};
$Env->debug(3)      if $opts{v};

my $ip = Net::Packet::IPv4->new(
   protocol => NP_IPv4_PROTOCOL_ICMPv4,
   dst      => $opts{i},
);

my $information = Net::Packet::ICMPv4->new(
   type => NP_ICMPv4_TYPE_INFORMATION_REQUEST,
   data => "test",
);

my $frame = Net::Packet::Frame->new(l3 => $ip, l4 => $information);

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
