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

use POE qw/Component::Client::Traceroute/;
use Getopt::Long;

use vars qw($opt_V $opt_h $opt_f $opt_p $opt_m $opt_w $opt_q $opt_S $opt_i
      $opt_l $opt_I $opt_D @hosts $VERSION);

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
       "I"     => \$opt_I, "icmp"         => \$opt_I,
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
my $debug_socket  = ($opt_D and $opt_D > 1) ? 1 : 0;
my $firsthop      = $opt_f || 1;
my $baseport      = $opt_p || 33434;
my $maxttl        = $opt_m || 30;
my $qtimeout      = $opt_w || 3;
my $queries       = $opt_q || 3;
my $sourceaddr    = $opt_S || '0.0.0.0';
my $interface     = $opt_i || undef;
my $packetlen     = $opt_l || 128;
my $useicmp       = $opt_I || 0;

@hosts            = @ARGV;

if (not @hosts)
{
   usage();
   exit 1;
}

POE::Component::Client::Traceroute->spawn
(
   Alias          => 'tracer',
   FirstHop       => $firsthop,
   MaxTTL         => $maxttl,
   Timeout        => 0,
   QueryTimeout   => $qtimeout,
   Queries        => $queries,
   BasePort       => $baseport,
   PacketLen      => $packetlen,
   SourceAddress  => $sourceaddr,
   PerHopPostback => 0,
   Device         => $interface,
   UseICMP        => $useicmp,
   Debug          => $debug,
   DebugSocket    => $debug_socket,
);

POE::Session->create
(
   inline_states   => {
      _start  => sub 
      {
         foreach my $address (@hosts)
         {
            $_[KERNEL]->post('tracer' => 'traceroute' => 'trace_complete' => 
                              $address );
            $_[HEAP]->{traces}++;
         }
      },
      _stop => sub { print "\n"; },
      trace_complete => sub
      {
         my ($kernel, $heap, $request, $response) = 
            @_[ KERNEL, HEAP, ARG0, ARG1 ];
         my ($destination, $options, $callback) = @$request;
         my ($hops, $data, $error)              = @$response;

         $heap->{traces}--;

         print "\n\n" if ($heap->{complete});

         if ($hops)
         {
            if ($error)
            {
               print "$destination not reached: $error\n";
            }
            else
            {
               print "$destination is $hops hops away\n";
            }

            foreach my $hop (@$data)
            {
               my $host       = $hop->{routerip};
               my $distance   = $hop->{hop};
               my @trip_times = @{$hop->{results}};

               printf "%3s  %-15s ",$distance,$host;
               my $x = 0;
               foreach my $rtt (@trip_times)
               {
                  if ($x and $x % 4 == 0) # Wrap every 4 lines
                  {
                     printf "\n%3s  %-15s ",$distance,$host;
                  }
                  if ($rtt eq "*") { printf "%-12s ", $rtt; }
                  else { printf "%-12s ", sprintf "%0.3f ms ", $rtt*1000; }
                  $x++;
               }
               print "\n";
            }
         }
         else
         {
            print $error if ($error); # Error performing traceroute
         }

         if ($heap->{traces} == 0)
         {
            $kernel->call( 'tracer' => 'shutdown' );
         }
         elsif ($debug)
         {
            printf "\n%i Traceroutes still running\n", $heap->{traces};
         }

         $heap->{complete}++;
      },
   }
);

$poe_kernel->run();

sub usage
{
   print "usage: $0 [-hV] [-I] [-f first_ttl] [-m max_hops] [-p port]\n",
         "\t[-S source_addr] [-i interface] [-l packetlen]\n",
         "\t[-w timeout] [-q nqueries] host [host] [host] ...\n";

   if ($opt_h)
   {
      print "\n",
            "  -h, --help        display this help and exit\n",
            "  -V, --version     display the version and exit\n",
            "  -I, --icmp        use ICMP instead of UDP\n",
            "  -f, --firsthop    set the first hop TTL\n",
            "  -m, --maxttl      set the maximum TTL before stopping\n",
            "  -p, --baseport    set the first UDP port to use\n",
            "  -S, --sourceaddr  set the source address to trace from\n",
            "  -i, --interface   set the source interface to trace from\n",
            "  -l, --packetlen   set the size of the packets to use\n",
            "  -w, --timeout     set the query timeout\n",
            "  -q, --queries     set the number of queries per hop\n";
   }
}

