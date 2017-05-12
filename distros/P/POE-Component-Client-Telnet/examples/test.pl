#!/usr/bin/perl

use POE qw(Component::Client::Telnet);

my $self = POE::Component::Client::Telnet->new(
#	debug => 1,
	telnet_options => [
	], # could put something here, or omit it
);

POE::Session->create(
	inline_states => {
		_start => \&_start,
		callback => \&callback,
		opened => \&opened,
		cont => \&cont,
		city_code => \&city_code,
		enter_city => \&enter_city,
		get_forecast => \&get_forecast,
		forecast => \&forecast,
	},
);

sub _start {
	#$self->open({ event => 'opened' },"rainmaker.wunderground.com");
	# alternative way
	$self->yield(open => { event => 'opened' } => "rainmaker.wunderground.com");
	$self->option_callback({ },"callback");
}

sub callback {
	warn "option callback!\n";
}

sub opened {
	# Wait for first prompt
	# $self->waitfor({ event => 'cont' },'/continue:.*$/');
	# alternative way
	$_[KERNEL]->post($self->session_id() => waitfor => { event => 'cont' } => '/continue:.*$/');
}

sub cont {
	# "hit return".
	$self->print({ event => 'city_code' },"");
}

sub city_code {
	# Wait for second prompt and respond with city code.
	$self->waitfor({ event => 'enter_city' },'/city code.*$/');
}

sub enter_city {
	$self->print({ event => 'get_forecast' },"BRD");
}

sub get_forecast {
	# Read and print the first page of forecast.
	$self->waitfor({ event => 'forecast' },'/[ \t]+press return to continue/i');
}

sub forecast {
	print "weather for BRD: ".$_[ARG0]->{result}."\n";
	#$_[KERNEL]->post($self->session_id => 'shutdown');
	# alternative
	$self->shutdown;
#	$self->DESTROY;
}

$poe_kernel->run();

exit;
