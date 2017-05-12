#!/usr/bin/perl

use strict;
use warnings;

use URI;

use Getopt::Long;
use IO::Async::Loop;
use Net::Async::HTTP;

my $FAMILY;
GetOptions(
   'local-host=s' => \my $LOCAL_HOST,
   'local-port=i' => \my $LOCAL_PORT,
   'timeout=f'    => \my $TIMEOUT,
   'ipv4|4'       => sub { $FAMILY = "inet" },
   'ipv6|6'       => sub { $FAMILY = "inet6" },
) or exit 1;

my $loop = IO::Async::Loop->new;

my $ua = Net::Async::HTTP->new(
   local_host => $LOCAL_HOST,
   local_port => $LOCAL_PORT,
   family     => $FAMILY,
   decode_content => 1,
);
$loop->add( $ua );

$ua->configure( timeout => $TIMEOUT ) if defined $TIMEOUT;

$ua->GET( $ARGV[0] )
   ->on_done( sub {
      my ( $response ) = @_;

      print $response->as_string;
   } )
   ->on_fail( sub {
      my ( $message ) = @_;

      print STDERR "Failed - $message\n";
   } )->get;
