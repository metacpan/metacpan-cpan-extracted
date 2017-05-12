#!/usr/bin/perl
#
# $Id: syn-send.pl 1640 2009-11-09 17:58:27Z gomor $
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

my $ip = Net::Packet::IPv4->new(
   dst => $opts{i},
);

my $tcp = Net::Packet::TCP->new(
   flags => NP_TCP_FLAG_SYN,
   dst   => $opts{p},
);

my $frame = Net::Packet::Frame->new(l3 => $ip, l4 => $tcp);

print "Request:\n";
print $frame->l3->print, "\n";
print $frame->l4->print, "\n";
$frame->send;

until ($Env->dump->timeout) {
   if ($frame->recv) {
      print "\nReply:\n";
      print $frame->reply->l3->print, "\n";
      print $frame->reply->l4->print, "\n";
      last;
   }
}

$Env->dump->stop;
$Env->dump->clean;
