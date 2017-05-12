#!/usr/bin/perl -w

# Exercise default random number generator
#
# Shows output from random_uuid_160 method

use lib '../lib';
use Net::OnlineCode::RNG;
use Net::OnlineCode;

use POSIX qw(floor);

my $null_seed = "\0" x 20;

my $rng = Net::OnlineCode::RNG->new($null_seed);
my $max = 0xffffffff;

for my $i (1..10000) {
  my $r = floor($rng->rand($i)); # range [0,$i)
  print "$r\n";
}

