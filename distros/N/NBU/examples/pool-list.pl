#!/usr/local/bin/perl

use strict;

use Getopt::Std;
use Time::Local;

my %opts;
getopts('d', \%opts);

use NBU;
NBU->debug($opts{'d'});

my @list = NBU::Pool->list;
for my $p (sort {$a->id <=> $b->id} @list) {
  printf("%2d: %s\n", $p->id, $p->name);
}
