#!/usr/bin/perl

use strict;
use warnings;

use Net::Gearman::Client;

my $func = shift @ARGV // die "Need func\n";
my $arg  = shift @ARGV // die "Need arg\n";

my $client = Net::Gearman::Client->new(
   PeerAddr => "127.0.0.1",
) or die "Cannot connect - $@\n";

$client->option_request( "exceptions" )->get;

my $result = $client->submit_job(
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
)->on_done( sub {
   my ( $result ) = @_;

   print $result . "\n";
})->on_fail( sub {
   my ( $msg, $name, $exception ) = @_;

   print STDERR "FAIL: $msg\n";
   print STDERR " >> $exception\n" if defined $name and $name eq "gearman" and defined $exception;
})->await;
