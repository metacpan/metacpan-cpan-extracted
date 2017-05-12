#!/usr/bin/env perl 
use strict;
use warnings;

use Ryu qw($ryu);

print "Had " . (
	$ryu->from(\*STDIN)
		->by_line
		->count
		->get
)[0] . " lines\n";

