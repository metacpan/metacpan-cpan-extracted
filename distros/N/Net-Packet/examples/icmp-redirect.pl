#!/usr/bin/perl
#
# $Id: icmp-redirect.pl 1640 2009-11-09 17:58:27Z gomor $
#
use strict;
use warnings;

use Getopt::Std;
my %opts;
getopts('i:d:I:g:v', \%opts);

die "Usage: $0 -i dstIp -g gateway [-d device] [-I srcIp] [-v]\n"
   unless $opts{i} && $opts{g};

use Net::Packet;

$Env->dev($opts{d}) if $opts{d};
$Env->ip ($opts{I}) if $opts{I};
$Env->debug(3)      if $opts{v};
$Env->noFrameAutoDump(1);

my $ip = Net::Packet::IPv4->new(
   protocol => NP_IPv4_PROTOCOL_ICMPv4,
   dst      => $opts{i},
);

my $iperror = Net::Packet::IPv4->new(dst => "192.168.0.1");

my $tcperror = Net::Packet::TCP->new(dst => 6666);

my $error = Net::Packet::Frame->new(l3 => $iperror, l4 => $tcperror);

my $icmp = Net::Packet::ICMPv4->new(
   type    => NP_ICMPv4_TYPE_REDIRECT,
   code    => NP_ICMPv4_CODE_FOR_HOST,
   gateway => $opts{g},
   error   => $error,
);

my $frame = Net::Packet::Frame->new(
   l3 => $ip,
   l4 => $icmp,
);

$frame->send;
