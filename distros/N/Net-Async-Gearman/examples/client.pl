#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Loop;
use Net::Async::Gearman::Client;

my $func = shift @ARGV // die "Need func\n";
my $arg  = shift @ARGV // die "Need arg\n";

my $loop = IO::Async::Loop->new;

my $client = Net::Async::Gearman::Client->new;
$loop->add( $client );

$client->connect(
   host => "127.0.0.1",
)->then( sub {
   $client->submit_job(
      func => $func,
      arg  => $arg,

      on_data => sub {
         my ( $data ) = @_;
         print $data;
      },

      on_status => sub {
         my ( $num, $denom ) = @_;
         print STDERR "\e[1;36mStatus $num / $denom\e[m...\n";
      },
   );
})->then( sub {
   my ( $result ) = @_;
   if( defined $result ) {
      print $result . "\n";
   }
   else {
      print STDERR "Job Failed\n";
   }
   Future->done;
})->get;
