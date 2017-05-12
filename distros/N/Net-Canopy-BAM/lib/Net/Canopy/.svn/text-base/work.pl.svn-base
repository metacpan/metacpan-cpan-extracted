#!/usr/bin/perl -w
use strict;

use BAM;
use Data::Dumper;

my $ncb = Net::Canopy::BAM->new();

my $qos = $ncb->buildQstr(
  upspeed => 128, 
  downspeed => 512, 
  upbucket => 200000,
  downbucket => 500000
);
print "Formatted QoS string:\n" . Dumper($qos);

print "Split QoS string:\n";
my $qhash = $ncb->parseQstr(qstr=>$qos);
print Dumper($qhash);

