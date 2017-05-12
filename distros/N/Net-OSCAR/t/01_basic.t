#!/usr/bin/perl

eval {
	require Test::More;
	Test::More->import(tests => 1);
};
if($@) {
	print "1..0 # Skipped: Couldn't load Test::More\n";
	exit 0;
}

use strict;
use warnings;
use lib "./blib/lib";

require_ok('Net::OSCAR');

1;
