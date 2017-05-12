#!/usr/bin/perl
use strict; use warnings;

use Net::Libdnet::Intf;
use Net::Libdnet::Entry::Intf;

my $h = Net::Libdnet::Intf->new;
$h->loop(\&intf_show);

sub intf_show {
   my ($entry, $data) = @_;
   my $e = Net::Libdnet::Entry::Intf->newFromHash($entry);
   print $e->print."\n";
}
