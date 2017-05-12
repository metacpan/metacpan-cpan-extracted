#!/usr/bin/perl -w

use POE qw(Component::Server::Chargen);

my ($object) = POE::Component::Server::Chargen->spawn( Alias => 'Echo-Server', BindPort => 8090, options => { trace => 1 } );

POE::Session->create(
	inline_states => { _start => \&simple_start,
			   _stop  => \&simple_stop, },
);

$poe_kernel->run();
exit 0;

sub simple_start {
}

sub simple_stop {
}
