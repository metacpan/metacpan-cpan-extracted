#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
  $| = 1;
  if ($> and ($^O ne 'VMS')) {
    print "$0 requires root privilege\n";
    exit 0;
  }
};

use Net::Traceroute::PurePerl;
use Getopt::Long;

use vars qw($opt_V $opt_h $opt_f $opt_p $opt_m $opt_w $opt_q $opt_S $opt_i
      $opt_l $opt_I $opt_D $opt_N $opt_n $host $VERSION);

$VERSION="1.0";

Getopt::Long::Configure('bundling');

GetOptions
   (
       "V"     => \$opt_V, "version"      => \$opt_V,
       "h"     => \$opt_h, "help"         => \$opt_h,
       "D+"    => \$opt_D, "debug+"       => \$opt_D,
       "f=i"   => \$opt_f, "firsthop=i"   => \$opt_f,
       "p=i"   => \$opt_p, "baseport=i"   => \$opt_p,
       "m=i"   => \$opt_m, "maxttl=i"     => \$opt_m,
       "w=i"   => \$opt_w, "timeout=i"    => \$opt_w,
       "q=i"   => \$opt_q, "nqueries=i"   => \$opt_q,
       "S=s"   => \$opt_S, "sourceaddr=s" => \$opt_S,
       "i=s"   => \$opt_i, "interface=s"  => \$opt_i,
       "l=i"   => \$opt_l, "packetlen=i"  => \$opt_l,
       "N=i"   => \$opt_N, "concurrent=i" => \$opt_N,
       "I"     => \$opt_I, "icmp"         => \$opt_I,
       "n"     => \$opt_n,
   );
       
if ($opt_V) {
   print "$0 version $VERSION\n";
   exit 0;
}

if ($opt_h) {
   usage();
   exit 0;
}

my $debug         = $opt_D || 0;
my $firsthop      = $opt_f || 1;
my $baseport      = $opt_p || 33434;
my $maxttl        = $opt_m || 30;
my $qtimeout      = $opt_w || 3;
my $queries       = $opt_q || 3;
my $sourceaddr    = $opt_S || '0.0.0.0';
my $interface     = $opt_i || undef;
my $packetlen     = $opt_l || 128;
my $useicmp       = $opt_I || 0;
my $concurrent    = $opt_N || 6;

my $resolve       = ($opt_n)     ? 0      : 1;
my $protocol      = ($useicmp)   ? 'icmp' : 'udp';

$host             = $ARGV[0];

if (not $host)
{
   usage();
   exit 1;
}

my $t = Net::Traceroute::PurePerl->new(
      host              => $host,
      debug             => $debug,
      first_hop         => $firsthop,
      base_port         => $baseport,
      max_ttl           => $maxttl,
      query_timeout     => $qtimeout,
      queries           => $queries,
      source_address    => $sourceaddr,
      packetlen         => $packetlen,
      protocol          => $protocol,
      concurrent_hops   => $concurrent,
      device            => $interface,
);
      
$t->traceroute();
$t->pretty_print($resolve);

sub usage
{
   print "usage: $0 [-hV] [-I] [-f first_ttl] [-m max_hops] [-p port]\n",
         "\t[-S source_addr] [-i interface] [-l packetlen] [-N concurrent]\n",
         "\t[-w timeout] [-q nqueries] host\n";

   if ($opt_h)
   {
      print "\n",
            "  -h, --help        display this help and exit\n",
            "  -V, --version     display the version and exit\n",
            "  -n                don't resolve router IPs to host names\n",
            "  -I, --icmp        use ICMP instead of UDP\n",
            "  -f, --firsthop    set the first hop TTL\n",
            "  -m, --maxttl      set the maximum TTL before stopping\n",
            "  -p, --baseport    set the first UDP port to use\n",
            "  -S, --sourceaddr  set the source address to trace from\n",
            "  -i, --interface   set the source interface to trace from\n",
            "  -l, --packetlen   set the size of the packets to use\n",
            "  -w, --timeout     set the query timeout\n",
            "  -q, --queries     set the number of queries per hop\n";
            "  -N, --concurrent  set the max number of concurrent queries\n";
   }
}

