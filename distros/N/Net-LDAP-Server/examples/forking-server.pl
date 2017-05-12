#!/usr/bin/perl

use strict;
use warnings;

package Listener;
use Net::Daemon;
use base 'Net::Daemon';
use MyDemoServer;

sub Run {
	my $self = shift;
	
	my $handler = MyDemoServer->new($self->{socket});
	while (1) {
		my $finished = $handler->handle;
		if ($finished) {
			# we have finished with the socket
			$self->{socket}->close;
			return;
		}
	}
}

package main;
my $listener = Listener->new({
	localport => 8080,
	logfile => 'STDERR',
	pidfile => 'none',
	mode => 'fork'
});
$listener->Bind;

1;
