#!/usr/bin/perl -w

######################################################################
### POE::Component::Client::Asterisk::Manager sample
### David Davis (xantus@cpan.org)
### 
### Prints Ring and the channel that the ring was recieved on
###
### Copyright (c) 2003-2004 David Davis and Teknikill.  All Rights
### Reserved. This module is free software; you can redistribute it
### and/or modify it under the same terms as Perl itself.
######################################################################

use strict;

use POE qw( Component::Client::Asterisk::Manager );

POE::Component::Client::Asterisk::Manager->new(
#	Options		=> { trace => 1, default => 1 },
	Alias		=> 'monitor',
	RemotePort	=> 5038,
	RemoteHost	=> "localhost",
	Username	=> "user",
	Password	=> "pass",
	CallBacks	=> {
		ring => {
			'Event' => 'Newchannel',
			'State' => 'Ring',
		},
	},
	inline_states => {
		_connected => sub {
			my $heap = $_[HEAP];
			$heap->{server}->put({'Action' => 'Command','Command' => 'show channels'});
		},
		ring => sub {
			my $input = $_[ARG0];
			print STDERR "RING! $input->{Channel}\n";
		},
	},
);

$poe_kernel->run();

exit 0;
