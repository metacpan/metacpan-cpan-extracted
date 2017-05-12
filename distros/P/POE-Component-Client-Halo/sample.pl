#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use POE;
use POE::Component::Client::Halo qw(:flags);

if(scalar(@ARGV) < 2) {
	print STDERR "Usage: $0 ip[:port] (info|detail)\n";
	exit 1;
}

my ($ip, $port) = split(/\:/, $ARGV[0]);
$port = 2302 unless defined $port;
my $cmd = $ARGV[1];

POE::Session->create(
	inline_states => {
		_start	=> sub {
			my $heap = $_[HEAP];
			$heap->{halo} = new POE::Component::Client::Halo(
				Alias => 'halo',
				Timeout => 15,
				Retry => 1);
			$poe_kernel->post('halo', $cmd, $ip, $port, 'pb');
			},
		pb	=> \&postback,
	}
);

sub postback {
	print Dumper($_[ARG4]), "\n";

	if(defined($_[ARG4]->{'PlayerFlags'})) {
		print "Player Flags:\n";
		foreach my $class (keys(%{$_[ARG4]->{'PlayerFlags'}})) {
			foreach(keys(%{$_[ARG4]->{'PlayerFlags'}->{$class}})) {
				next unless defined halo_player_flag($_, $_[ARG4]->{'PlayerFlags'}->{$class}->{$_});
				print "$_ => ", halo_player_flag($_, $_[ARG4]->{'PlayerFlags'}->{$class}->{$_}), "\n";
			}
		}
	};
	if(defined($_[ARG4]->{'GameFlags'})) {
		print "\nGame Flags:\n";
		foreach(keys(%{$_[ARG4]->{'GameFlags'}})) {
			next unless defined halo_game_flag($_, $_[ARG4]->{'GameFlags'}->{$_});
			print "$_ => ", halo_game_flag($_, $_[ARG4]->{'GameFlags'}->{$_}), "\n";
		}
	};
}

$poe_kernel->run();
