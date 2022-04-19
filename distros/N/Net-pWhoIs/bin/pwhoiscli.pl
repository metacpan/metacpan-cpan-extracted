#!/usr/bin/env perl

use strict;
use Net::pWhoIs;

my $obj = Net::pWhoIs->new();

my $output = $obj->pwhois(\@ARGV);

print $obj->printReport($output);
