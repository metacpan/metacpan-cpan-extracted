#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Net::Routing qw($Error :constants);

my $route = Net::Routing->new(family => NR_FAMILY_INET6());
if (! defined($route)) {
   print "ERROR: $Error\n";
   exit(1);
}

$route->list;

exit(0);
