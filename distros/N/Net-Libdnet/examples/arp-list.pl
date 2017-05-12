#!/usr/bin/perl
use strict; use warnings;

use Net::Libdnet::Arp;

my $h = Net::Libdnet::Arp->new;
$h->loop(\&arp_show);

sub arp_show {
   my ($entry, $data) = @_;
   print "IP: ".$entry->{arp_pa}." MAC: ".$entry->{arp_ha}."\n";
}
