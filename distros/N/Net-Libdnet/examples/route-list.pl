#!/usr/bin/perl
use strict; use warnings;

use Net::Libdnet::Route;

my $h = Net::Libdnet::Route->new;
$h->loop(\&route_show);

sub route_show {
   my ($entry, $data) = @_;
   print "[".$entry->{route_dst}."] -> [".$entry->{route_gw}."]\n";
}
