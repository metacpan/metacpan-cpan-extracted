#!/usr/bin/perl
#
# DESCRIPTION:
#       Test sending more than one passive result to nrd
#
# COPYRIGHT:
#       Copyright (C) 2007 Altinity Limited
#       Copyright is freely given to Ethan Galstad if included in the NSCA distribution
#
# LICENCE:
#       GNU GPLv2

use lib 't';

use strict;
use NSCATest;
use Test::More;
use Clone qw(clone);

my $iterations = 10;

plan tests => (3 * 3);

my $data = [
	["hostname", "0", "Plugin output"],
	["host", "service", 0, "A good result here"],
	];

my $copies = [];
for (1 .. $iterations) {
	my $c = clone($data);
	push @$copies, @$c;
}

foreach my $config ('plain', 'encrypt', 'digest'){
  foreach my $type ('--server_type=Single', '--server_type=Fork', '--server_type=PreFork') {
	my $nsca = NSCATest->new( config => $config );

	$nsca->start($type);

	my $i = 0;
	for($i; $i < $iterations; $i++) {
		$nsca->send($data);
	}
	sleep 1;		# Need to wait for --daemon to finish processing

	my $output = $nsca->read_cmd;

	is_deeply( $output, $copies );

	$nsca->stop;
  }
}
