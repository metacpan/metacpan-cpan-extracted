#!/usr/bin/perl -w

use POE qw(Component::Server::Daytime);

my ($object) = POE::Component::Server::Daytime->spawn( Alias => 'Echo-Server', BindPort => 8090, Quote => 'A closed mouth gathers no foot.', options => { trace => 1 } );

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
