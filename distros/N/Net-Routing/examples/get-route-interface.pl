#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Net::Routing qw($Error :constants);

my $interface = shift or die("Give interface");

my $route = Net::Routing->new(target => $interface);
if (! defined($route)) {
   print "ERROR: $Error\n";
   exit(1);
}

$route->list;

exit(0);
