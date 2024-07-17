#!/usr/bin/perl

use v5.14;
use warnings;

use Net::Prometheus;

use IO::Async::Loop;
use Net::Async::HTTP::Server::PSGI;

use Metrics::Any::Adapter 'Prometheus';

use constant LISTEN_PORT => 8200;

my $client = Net::Prometheus->new;

$client->new_gauge(
   name => "ten",
   help => "The number ten",
)->set( 10 );

printf STDERR "Serving metrics on http://[::]:%d\n", LISTEN_PORT;

my $loop = IO::Async::Loop->new;

$client->export_to_IO_Async( $loop, port => LISTEN_PORT );

$loop->run;
