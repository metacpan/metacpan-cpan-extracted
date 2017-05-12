#!/usr/bin/perl -w

use strict;
use POE qw(Component::Client::Rcon);

if(scalar(@ARGV) < 3) {
	print STDERR "Usage: $0 ip:port password command\n";
	exit 1;
}

my ($ip, $port) = split(/\:/, $ARGV[0]);
$port = 27015 unless defined $port;
my $pw = $ARGV[1];
my $cmd = join(' ', splice(@ARGV, 2));

POE::Session->create(
	inline_states => {
		_start	=> sub {
			my $heap = $_[HEAP];
			$heap->{rcon} = new POE::Component::Client::Rcon(
				Alias => 'rcon',
				Timeout => 15,
				Retry => 1,
				Bytes => 28000);
			$poe_kernel->post('rcon', 'rcon', 'hl', $ip, $port,
				$pw, $cmd, 'pb', undef);
			},
		pb	=> sub {
			print $_[ARG5], "\n";
		}
	}
);
$poe_kernel->run();
