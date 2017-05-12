#!/usr/bin/perl
#
# $Id: syn-scan.pl 1640 2009-11-09 17:58:27Z gomor $
#
use strict;
use warnings;

use Getopt::Std;

my %opts;
getopts('6i:I:p:d:vr:ocfs:F:', \%opts);

die
"Usage: $0 -i target [-p ports] [-I source] [-d device] [-v]\n".
"  -p range  port range to scan (example: 1-1024) (default ~ 1660)\n".
"  -r n      number of SYN packet try (default: 3)\n".
"  -s n      time spacing between two probes (default: 150 microseconds)\n".
"  -6        SYN scan over IPv6 (default: not)\n".
"  -o        print open ports result (default: yes)\n".
"  -f        print filtered ports result (default: yes)\n".
"  -c        print closed ports result (default: no)\n".
"  -F        offline scan mode\n".
""
   unless $opts{i} || $opts{F};

use Net::Packet;

$Env->dev($opts{d}) if $opts{d};
$Env->ip ($opts{I}) if $opts{I};
$Env->debug(3)      if $opts{v};

do { $opts{o} = $opts{f} = 0 } if  $opts{c} && !$opts{o} && !$opts{f};
do { $opts{c} = $opts{f} = 0 } if  $opts{o} && !$opts{c} && !$opts{f};
do { $opts{o} = $opts{c} = 0 } if  $opts{f} && !$opts{c} && !$opts{o};
do { $opts{o} = $opts{f} = 1 } if !$opts{c} && !$opts{f} && !$opts{o};

$opts{r} = 3   unless $opts{r};
$opts{s} = 150 unless $opts{s};

# nmap 3.77 default ports (here, ~ 1664)
my $defaultPorts =
   '1-1024,1025-1027,1029-1033,1040,1050,1058,1059,1067,1068,1076,1080,1083,'.
   '1084,1103,1109,1110,1112,1127,1139,1155,1178,1212,1214,1220,1222,1234,'.
   '1241,1248,1337,1346-1381,1383-1552,1600,1650-1652,1661-1672,1680,1720,'.
   '1723,1755,1761-1764,1827,1900,1935,1984,1986-2028,2030,2032-2035,2038,'.
   '2040-2049,2053,2064,2065,2067,2068,2105,2106,2108,2111,2112,2120,2121,'.
   '2201,2232,2241,2301,2307,2401,2430-2433,2500,2501,2564,2600-2605,2627,'.
   '2628,2638,2766,2784,2809,2903,2998,3000,3001,3005,3006,3049,3052,3064,'.
   '3086,3128,3141,3264,3268,3269,3292,3306,3333,3372,3389,3421,3455,3456,'.
   '3457,3462,3531,3632,3689,3900,3984,3985,3986,3999,4000,4008,4045,4132,'.
   '4133,4144,4224,4321,4333,4343,4444,4480,4500,4557,4559,4660,4672,4899,'.
   '4987,4998,5000,5001-5003,5010,5011,5050,5100-5102,5145,5190-5193,5232,'.
   '5236,5300-5305,5308,5400,5405,5490,5432,5510,5520,5530,5540,5550,5555,'.
   '5631,5632,5680,5713-5717,5800-5803,5900-5903,5977-5979,5997-6009,6017,'.
   '6050,6101,6103,6105,6106,6110-6112,6141,6142,6143,6144,6145-6148,6346,'.
   '6400,6401,6543,6544,6547,6548,6502,6558,6588,6666-6668,6969,6699,'.
   '7000-7010,7070,7100,7200,7201,7273,7326,7464,7597,8000,8007,8009,'.
   '8080-8082,8443,8888,8892,9090,9100,9111,9152,9535,9876,9991,9992,9999,'.
   '10000,10005,10082,10083,11371,12000,12345,12346,13701,13702,13705,13706,'.
   '13708-13722,13782,13783,15126,16959,17007,17300,18000,18181-18185,18187,'.
   '19150,20005,22273,22289,22305,22321,22370,26208,27000-27010,27374,27665,'.
   '31337,32770-32780,32786,32787,38037,38292,43188,44334,44442,44443,47557,'.
   '49400,54320,61439-61441,65301'
;

use Time::HiRes qw(usleep);

my @open;
my @closed;
my @filtered;
my @firewalled;

$opts{F} ? scanOffline() : scanOnline();

###

sub scanOnline {
   my $d4 = Net::Packet::DescL4->new(
      target => $opts{i},
      family => $opts{6} ? NP_LAYER_IPv6 : NP_LAYER_IPv4,
   );

   my $filter;
   if ($opts{6}) {
      $filter = "(tcp and src host @{[getHostIpv6Addr($opts{i})]}".
                " and dst host @{[$Env->ip6]})".
                " or (icmp6 and dst host @{[$Env->ip6]})";
   }
   else {
      $filter = "(tcp and src host @{[getHostIpv4Addr($opts{i})]}".
                " and dst host @{[$Env->ip]})".
                " or (icmp and dst host @{[$Env->ip]})";
   }

   my $dump = Net::Packet::Dump->new(
      file          => "netpacket-syn-scan-$opts{i}.pcap",
      filter        => $filter,
      overwrite     => 1,
      unlinkOnClean => 0,
   );

   my @out;
   push @out, Net::Packet::Frame->new(l4 => Net::Packet::TCP->new(dst => $_))
      for explodePorts($opts{p} || $defaultPorts);

   for (1..$opts{r}) {
      do { usleep($opts{s}); $_->reSend } for @out;

      until ($dump->timeout) {
         $_->recv for @out;

         my $notAllReceived;
         do { $notAllReceived++ unless $_->reply } for @out;
         last unless $notAllReceived;
      }

      $dump->timeoutReset;
   }

   for (@out) {
      my $reply = $_->reply;

      unless ($reply) {
         push @filtered, $_->l4->dst;
         next;
      }

      if ($reply->isTcp) {
         if ($reply->l4->haveFlagSyn && $reply->l4->haveFlagAck) {
            push @open, $reply->l4->src;
         }
         elsif ($reply->l4->haveFlagRst) {
            push @closed, $reply->l4->src;
         }
      }
      elsif ($reply->isIcmp) {
         push @firewalled, $reply->l4->error->l4->dst;
      }
   }

   $dump->stop;
   $dump->clean;

   printResult(\@open,       'open')     if $opts{o};
   printResult(\@closed,     'closed')   if $opts{c};
   printResult(\@filtered,   'filtered') if $opts{f};
   printResult(\@firewalled, 'firewalled');
}

sub scanOffline {
   my $dump = Net::Packet::Dump->new(
      mode          => NP_DUMP_MODE_OFFLINE,
      file          => $opts{F},
      unlinkOnClean => 0,
   );
   $dump->start;
   $dump->nextAll;
   $dump->stop;
   $dump->clean;

   for ($dump->frames) {
      next unless $_->isTcp;

      my $src = $_->l3->src. ':'. $_->l4->src;
      if ($_->l4->haveFlagSyn && $_->l4->haveFlagAck) {
         push @open, $src;
      }
      elsif ($_->l4->haveFlagRst && $_->l4->haveFlagAck) {
         push @closed, $src;
      }
      elsif ($_->isIcmp && $_->l4->isTypeDestinationUnreachable) {
         push @firewalled, $_->l4->error->l3->dst. ':'. $_->l4->error->l4->dst;
      }
   }

   printResultOffline(\@open,       'open');
   printResultOffline(\@closed,     'closed');
   printResultOffline(\@firewalled, 'firewalled');
}

sub printResult {
   my $ary   = shift;
   my $state = shift;
   printf "%5s/tcp\t%-15s\t%-15s\n",
      $_, (getservbyport($_, 'tcp'))[0] || "", $state
         for sort { $a <=> $b } @$ary;
}

sub printResultOffline {
   my $ary   = shift;
   my $state = shift;
   for (@$ary) {
      /.*:(\d+)/;
      printf "%35s/tcp\t%-15s\t%-15s\n",
         $_, (getservbyport($1, 'tcp'))[0] || "", $state
   }
}
