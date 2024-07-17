#!/usr/bin/perl

use v5.14;
use warnings;

use Net::Prometheus;

use Metrics::Any::Adapter 'Prometheus';

use constant LISTEN_PORT => 8200;

# Try to find a usable Future::IO impl
foreach (qw( UV Glib IOAsync Tickit )) {
   ( my $file = ( my $class = "Future::IO::Impl::$_" ) . ".pm" ) =~ s(::)(/)g;
   eval { require $file } and do {
      print STDERR "Using $class\n";
      last;
   };
}

my $client = Net::Prometheus->new;

$client->new_gauge(
   name => "ten",
   help => "The number ten",
)->set( 10 );

printf STDERR "Serving metrics on http://[::]:%d\n", LISTEN_PORT;

$client->export_to_Future_IO( port => LISTEN_PORT )->await;
