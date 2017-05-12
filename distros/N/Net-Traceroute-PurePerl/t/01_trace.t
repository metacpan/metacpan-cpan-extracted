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

use Net::Traceroute::PurePerl;
use Test::More tests => 5;

sub DEBUG () { return 0 }

my $host = 'www.perl.org';
my $t    = "";

eval {
   $t = Net::Traceroute::PurePerl->new(
      host              => $host,
      debug             => DEBUG,
      first_hop         => 1,
      base_port         => 33434,
      max_ttl           => 15,
      query_timeout     => 3,
      queries           => 3,
      source_address    => '0.0.0.0',
      packetlen         => 40,
      protocol          => 'udp',
      concurrent_hops   => 6,
      device            => undef,
   );
};

ok(
      ref $t eq 'Net::Traceroute::PurePerl',
      'Object created successfully'
) or diag($@);

if ($t)
{

   my $success;
   eval {   local $SIG{ALRM} = sub { die "alarm" }; 
            alarm 30; # Should never take longer than 24 seconds 
            $success = $t->traceroute;
            alarm 0;
   };

   ok(
         defined $success,
         'Traceroute completed successfully'
   ) or diag($@);

   my $success2;
   eval {   $t->protocol('icmp');
            local $SIG{ALRM} = sub { die "alarm timed out" }; 
            alarm 30; # Should never take longer than 24 seconds 
            $success2 = $t->traceroute;
            alarm 0;
   };

   ok(
         defined $success2,
         'ICMP Traceroute completed successfully'
   ) or diag($@);
}
else
{
   foreach (1 .. 2)
   {
      fail('Could not create trace object');
   }
   eval { $t = Net::Traceroute::PurePerl->new() };
}

eval { $t->protocol('notimplemented'); $t->traceroute; };

ok(
      $@ =~ /Parameter `protocol\'/,
      "Bad protocol detected successfully"
);

eval { $t->protocol('icmp'); $t->host('badhost.x'); $t->traceroute; };

ok(
      $@ =~ /Could not resolve host/,
      "Bad host detected successfully"
);

# The clone method currently fails

# my $t2;
# eval { 
#    $t = Net::Traceroute::PurePerl->new(host => 'www.perl.org', queries=>'2'); 
#    $t2 = $t->clone(); 
# };

# is_deeply($t, $t2, "Clone works") or diag ("Clone failed");

