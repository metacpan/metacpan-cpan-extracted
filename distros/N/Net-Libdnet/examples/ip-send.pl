#!/usr/bin/perl
use strict; use warnings;

use Net::Libdnet::Ip;

my $h = Net::Libdnet::Ip->new;
$h->send('G'x60);
