#!/usr/bin/perl
use strict; use warnings;

use Net::Libdnet::Fw;
use Data::Dumper;

my $h = Net::Libdnet::Fw->new;
$h->loop(\&fw_print);

sub fw_print {
   my ($rule, $data) = @_;
   print Dumper($rule)."\n";
}
