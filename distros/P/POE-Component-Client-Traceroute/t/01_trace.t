#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
  $| = 1;
  if ($> and ($^O ne 'VMS')) {
    print "1..0 # skipped: Traceroute requires root privilege\n";
    exit 0;
  }
};

sub POE::Kernel::ASSERT_DEFAULT () { 1 };
use POE qw/Component::Client::Traceroute/;
use Test::More tests => 4;

sub DEBUG () { 0 }

my $address1 = 'www.google.com';
my $address2 = 'www.cisco.com';

POE::Component::Client::Traceroute->spawn
(
   Alias          => 'tracer',
   FirstHop       => 1,
   MaxTTL         => 15,
   Timeout        => 60,
   QueryTimeout   => 3,
   Queries        => 3,
   BasePort       => 33434,
   PacketLen      => 128,
   SourceAddress  => '0.0.0.0',
   PerHopPostback => 0,
   Device         => undef,
   UseICMP        => 0,
   Debug          => 0,
   DebugSocket    => 0,
);

POE::Session->create
(
   inline_states   => {
      _start  => sub 
      {
         my $qtimeout      = 3;
         my $queries       = 3;
         $_[KERNEL]->post('tracer' => 'traceroute' => 'trace_complete' => 
                           $address1,
                           [
                              QueryTimeout   => $qtimeout,
                              Queries        => $queries,
                              PerHopPostback => 'trace_row',
                              Callback       => 0,
                           ] );
         $_[KERNEL]->post('tracer' => 'traceroute' => 'trace_complete' => 
                           $address2,
                           [
                              QueryTimeout   => $qtimeout,
                              Queries        => $queries,
                              Callback       => 1,
                              UseICMP        => 1,
                           ] );

         $_[HEAP]->{traces} = 2;
      },
      _stop => sub
      {
         my $heap = $_[HEAP];

         ok(
           (
             $heap->{rows} > 0 and
             $heap->{complete} == 2
           ),
           "tracer client sessions completed successfully"
         );

         undef;
      },
      trace_row => sub
      {
         my ($kernel, $heap, $request, $response) = 
            @_[ KERNEL, HEAP, ARG0, ARG1 ];
         my ($destination, $options, $callback) = @$request;
         my ($currenthop, $data, $error)        = @$response;

         if ($error)
         {
            DEBUG and print "$destination $currenthop: $error\n";
         }
         else
         {
            foreach my $hop (@$data)
            {
               my $host       = $hop->{routerip};
               my $distance   = $hop->{hop};
               my @trip_times = @{$hop->{results}};

               if (DEBUG)
               {
                  print "$distance  $host ";
                  foreach my $rtt (@trip_times)
                  {
                     if ($rtt eq "*")
                     {
                        print "$rtt ";
                     }
                     else
                     {
                        printf "%0.3fms ", $rtt*1000;
                     }
                  }
                  print "\n";
               }
            }
         }
         $heap->{rows}++;
      },
      trace_complete => sub
      {
         my ($kernel, $heap, $request, $response) = 
            @_[ KERNEL, HEAP, ARG0, ARG1 ];
         my ($destination, $options, $callback) = @$request;
         my ($hops, $data, $error)              = @$response;

         $heap->{traces}--;

         DEBUG and print "\n\n" if ($heap->{traces} == 0);

         if (not $callback)
         {
            ok ( $heap->{rows} > 0, "PerRowPostback got rows" );
         }

         if ($hops)
         {
            if ($error)
            {
               DEBUG and print "$destination not reached: $error\n";
            }
            else
            {
               DEBUG and print "$destination is $hops hops away\n";
            }

            if ($callback == 1)
            {
               foreach my $hop (@$data)
               {
                  my $host       = $hop->{routerip};
                  my $distance   = $hop->{hop};
                  my @trip_times = @{$hop->{results}};

                  if (DEBUG)
                  {
                     print "$distance  $host ";
                     foreach my $rtt (@trip_times)
                     {
                        if ($rtt eq "*")
                        {
                           print "$rtt ";
                        }
                        else
                        {
                           printf "%0.3fms ", $rtt*1000;
                        }
                     }
                     print "\n";
                  }
               }
            }
            ok ( $hops >= 1, "Got results from traceroute" );
         }
         else
         {
            ok (! $error, "Traceroute error") or diag($error);

            if ($error) # Error performing traceroute
            {
               DEBUG and print $error;
            }
         }

         if ($heap->{traces} == 0)
         {
            $kernel->call( 'tracer' => 'shutdown' );
         }

         $heap->{complete}++;
      },
   }
);

$poe_kernel->run();


