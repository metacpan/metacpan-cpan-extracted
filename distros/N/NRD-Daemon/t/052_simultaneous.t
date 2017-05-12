#!/usr/bin/perl
#
# DESCRIPTION:
#       Test sending lots of results at the same time
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
use Parallel::Forker;

my $iterations = 3;
my $timeout = 8;

plan tests => (3 * 3 * 2);

my $data = [
        ["hostname", "0", "Plugin output"],
        ["hostname-with-other-bits", "1", "More data to be read"],
        ["hostname.here", "2", "Check that ; are okay to receive"],
	["long_output", 0, 'x' x 10240 ],
        ["host", "service", 0, "A good result here"],
        ["host54", "service with spaces", 1, "Warning! My flies are undone!"],
        ["host-robin", "service with a :)", 2, "Critical? Alert! Alert!"],
        ["host-batman", "another service", 3, "Unknown - the only way to travel"],
	["long_output", "service1", 0, 'x' x 10240 ], #10K of plugin output
	];


my $Fork = Parallel::Forker->new( use_sig_child => 1 );
$SIG{CHLD} = sub { Parallel::Forker::sig_child($Fork); };
$SIG{TERM} = sub { $Fork->kill_tree_all('TERM') if $Fork; die "Quitting..."; };

foreach my $config ('plain', 'encrypt', 'digest'){
  foreach my $type ('--server_type=Single', '--server_type=Fork', '--server_type=PreFork') {
	my $expected = [];
	my $nsca = NSCATest->new( config => $config, timeout => $timeout );

	$nsca->start($type);

	for (my $i = 0; $i < $iterations; $i++) {
		my $c = clone($data);
		push @$c, [ "host_$i", 2, "Some unique data: ".rand() ];
		push @$c, [ "host_$i", "service", 2, "Some unique data: ".rand() ];
		push @$expected, @$c;
		$Fork->schedule( 
			run_on_start => sub { $nsca->child_spawned(1); $nsca->send($c) },
			);
	}

	$Fork->ready_all;
	$Fork->wait_all;

	sleep 10;		# Need to wait for --daemon to finish processing

	my $output = $nsca->read_cmd;

	is( scalar @$output, scalar @$expected, "Got all ".scalar @$expected." packets of data" );
	is_deeply_sorted( $output, $expected, "All data as expected" );

	$nsca->stop;
  }
}

sub is_deeply_sorted {
	my ($expected, $against, $text) = @_;
	my $e = [ sort map { join(";", map { $_ } @$_) } @$expected ];
	my $a = [ sort map { join(";", map { $_ } @$_) } @$against ];

	#for (my $i =0; $i<scalar(@$e); $i++){
           #print "$e->[$i] vs $a->[$i]\n";
	#   cmp_ok($e->[$i], 'eq', $a->[$i], "$e->[$i] vs $a->[$i]");
	#}

	is_deeply($e, $a, $text);
}

