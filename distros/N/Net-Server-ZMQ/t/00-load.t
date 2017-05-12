#!/usr/bin/env perl

use Test::More tests => 1;

BEGIN {
	use_ok('Net::Server::ZMQ') || print "Bail out!\n";
}

diag("Testing Net::Server::ZMQ $Net::Server::ZMQ::VERSION, Perl $], $^X");
