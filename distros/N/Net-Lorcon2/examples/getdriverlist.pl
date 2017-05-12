#!/usr/bin/perl
#
# $Id: getdriverlist.pl 31 2015-02-17 07:04:36Z gomor $
#
use strict;
use warnings;

use Net::Lorcon2 qw(:subs);

my @cards = lorcon_list_drivers();

use Data::Dumper;
print Dumper(\@cards);
