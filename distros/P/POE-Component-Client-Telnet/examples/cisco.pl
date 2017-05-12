#!/usr/bin/perl

use POE qw(Component::Client::Telnet);

my $self = POE::Component::Client::Telnet->new(
#	debug => 1,
	'package' => 'Net::Telnet::Cisco',
	telnet_options => [
		Timeout => 10,
		Prompt => '/bash\$ $/'
	], # could put something here, or omit it
);

POE::Session->create(
	inline_states => {
		_start => \&_start,
		callback => \&callback,
		opened => \&opened,
		logged_in => \&logged_in,
		who => \&who,
	},
);

sub _start {
	# preferred way
	#$self->open({ event => 'opened' },"sparky");
	# alternative way
	$self->yield(open => { event => 'opened' } => "sparky");
}

sub opened {
	# Wait for first prompt
	# $self->waitfor({ event => 'cont' },'/continue:.*$/');
	$self->login({ event => 'logged_in' },"username","password");
	# alternative way
	$_[KERNEL]->post($self->session_id() => login => { event => 'logged_in' } => "username" => "password");
}

sub logged_in {
	$self->cmd({ event => 'who', 'wantarray' => 1 },"who");
}

sub who {
	print @{$self->{result}};
	
	$self->shutdown;
}

$poe_kernel->run();

exit;
