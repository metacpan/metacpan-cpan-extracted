#!/usr/bin/perl

# Load everything else which can get loaded on-demand...

eval {
	require Test::More;
	Test::More->import();
};
if($@) {
	print "1..0 # Skipped: Couldn't load Test::More\n";
	exit 0;
}

use strict;
use warnings;
use lib "./blib/lib";

plan(tests => 1);

require Net::OSCAR::XML;
Net::OSCAR::XML::load_xml();
require_ok("Net::OSCAR::MethodInfo");

1;
