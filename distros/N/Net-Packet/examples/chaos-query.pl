#!/usr/bin/perl
#
# $Id: chaos-query.pl 1640 2009-11-09 17:58:27Z gomor $
#
use strict;
use warnings;

use Getopt::Std;
my %opts;
getopts('d:i:I:v', \%opts);

die "Usage: $0 -i dstIp [-I srcIp] [-d device] [-v]\n"
   unless $opts{i};

use Net::Packet;

$Env->dev($opts{d}) if $opts{d};
$Env->ip ($opts{I}) if $opts{I};
$Env->debug(3)      if $opts{v};

my $l3 = Net::Packet::IPv4->new(
   protocol => NP_IPv4_PROTOCOL_UDP,
   dst      => $opts{i},
);

my $l4 = Net::Packet::UDP->new(dst => 53);

my $l7 = Net::Packet::Layer7->new(
   data => "\x33\xde\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00\x07\x76\x65".
           "\x72\x73\x69\x6f\x6e\x04\x62\x69\x6e\x64\x00\x00\x10\x00\x03",
);

my $frame = Net::Packet::Frame->new(l3 => $l3, l4 => $l4, l7 => $l7);

print "Request:\n";
print $frame->l3->print, "\n";
print $frame->l4->print, "\n";
print $frame->l7->print, "\n";
$frame->send;

until ($Env->dump->timeout) {
   if ($frame->recv) {
      print "\nReply:\n";
      print $frame->reply->l3->print, "\n";
      print $frame->reply->l4->print, "\n";
      print $frame->reply->l7->print, "\n";
      last;
   }
}

$Env->dump->stop;
$Env->dump->clean;
