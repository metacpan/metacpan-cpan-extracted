#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Net::LibAsyncNS;

my $method = "res_query";

my $type  = 1;
my $class = 1;

GetOptions(
   '--search' => sub { $method = "res_search" },

   '--type=i'  => \$type,
   '--class=i' => \$class,
) or exit 1;

my $host = shift @ARGV or die "Need host\n";

my $asyncns = Net::LibAsyncNS->new( 1 );

my $query = $asyncns->$method( $host, $class, $type );

$asyncns->wait( 1 ) while !$query->isdone;

my $answer = $asyncns->res_done( $query );
defined $answer or die "res_query: $!\n";

while( length $answer ) {
   my $chunk = substr $answer, 0, 16, "";
   my @chars = split //, $chunk;
   print "| ";
   print sprintf("%02x ", ord $_) for @chars;
   print "   " x ( 16 - @chars );
   print "| ";
   print ord $_ > 0x20 && ord $_ < 0x7f ? $_ : "." for @chars;
   print " " x ( 16 - @chars );
   print " |\n";
}
