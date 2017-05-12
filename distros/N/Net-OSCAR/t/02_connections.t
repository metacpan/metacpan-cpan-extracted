#!/usr/bin/perl

# The Connection modules are loaded on demand,
# so we test loading them all here.

eval {
	require Test::More;
	Test::More->import(tests => 5);
};
if($@) {
	print "1..0 # Skipped: Couldn't load Test::More\n";
	exit 0;
}

use strict;
use warnings;
use lib "./blib/lib";

require_ok('Net::OSCAR');
require_ok('Net::OSCAR::Connection');
require_ok('Net::OSCAR::Connection::Direct');
require_ok('Net::OSCAR::Connection::Chat');
require_ok('Net::OSCAR::Connection::Server');

1;
