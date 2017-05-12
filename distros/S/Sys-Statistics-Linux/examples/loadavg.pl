#!/usr/bin/perl
use strict;
use warnings;
use Sys::Statistics::Linux;

$|++;

my $header   = 20;
my $interval = 1;
my $column   = 10;
my @order    = qw(avg_1 avg_5 avg_15);
my $h_int    = $header;
my $lxs      = Sys::Statistics::Linux->new(loadavg => 1);

while ( 1 ) {
   my $stats = $lxs->get->loadavg;

   if ($h_int == $header) {
      printf "%${column}s", $_ for ('date', 'time', @order);
      print "\n";
   }

   my ($date, $time) = $lxs->gettime;

   printf "%${column}s", $_ for ($date, $time);
   printf "%${column}s", $stats->{$_} for @order;
   print "\n";

   $h_int = $header if --$h_int == 0;
   sleep $interval;
}
