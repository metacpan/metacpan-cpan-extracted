#!/usr/bin/env perl
use strict;
use warnings;
use Ryu qw($ryu);
my ($lines) =
	$ryu->from(\*STDIN)
		->by_line
		->filter(qr/\h/)
		->count
		->get;
print "Had $lines line(s) containing whitespace\n";
