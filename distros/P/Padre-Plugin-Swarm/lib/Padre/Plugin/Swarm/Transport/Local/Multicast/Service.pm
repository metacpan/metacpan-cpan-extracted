package Padre::Plugin::Swarm::Transport::Local::Multicast::Service;
use strict;
use warnings;
use JSON;
use Padre::Wx      ();
use Padre::Task ();
use Padre::Logger;
use Padre::Swarm::Message;
use IO::Select;
use IO::Socket::Multicast;

our $VERSION = '0.11';
our @ISA     = 'Padre::Task';

use Class::XSAccessor
	accessors => {
		service    => 'service',
		client     => 'client',
	};


sub hangup {
	my $self = shift;
	$self->client->shutdown(1) if $self->client;
	$self->client(undef);
	$self->handle->message(on_recv=>'DEAD');
}

sub terminate {
	my $self = shift;
	$self->client(undef);
	$self->handle->message(on_recv=>'DEAD');
}


sub run {
	my $self = shift;
	TRACE( "Running" ) if DEBUG;
	$self->start;
	while ($self->running) {
		$self->service_loop;
	}
	TRACE("Finished Running") if DEBUG;
	
}

sub service_loop {
	my $self = shift;
	
	if (my ($message) = $self->poll(0.2) ) {
		$self->handle->message(on_recv=>$message);
	}
	
	return 1;
}


sub poll  {
	my $self = shift;
	my $timeout = shift || 0.5;
	my $poll = IO::Select->new;
	$poll->add( $self->{client} );
	my ($ready) = $poll->can_read($timeout);
	if ($ready) {
		my ($message) = $self->receive($ready);
		if ($message) {
			return $message;
		}
	}
	return ();
}

sub receive {
	my $self = shift;
	my $sock = shift;
	my $buffer;
	my $remote = $sock->recv( $buffer, 65535 );
	if  ( $remote ) {
		TRACE("Got data '$buffer'") if DEBUG;
		#my $marshal = Padre::Plugin::Swarm::Transport->_marshal;
		#my ($rport,$raddr) = sockaddr_in $remote;
		#my $ip = inet_ntoa $raddr;
		return $buffer;
	}
	
}

sub start {
	my $self = shift;
	TRACE( "Starting" ) if DEBUG;
	my $client = IO::Socket::Multicast->new(
		LocalPort => 12000,
		ReuseAddr => 1,
	) or die $!;
	$client->mcast_add('239.255.255.1'); #should have the interface
	$client->mcast_loopback( 1 );
	
	$self->{client} = $client;
	$self->{running} = 1;
	$self->handle->message(on_recv=>'ALIVE');

}

sub on_recv {
	my $self = shift;
	TRACE( "on_recv handler with @_" ) if DEBUG;
	if ( $self->{owner} ) {
		TRACE( "Informing Owner" ) if DEBUG;
		my $owner = $self->owner;
		TRACE("Owner is $owner" ) if DEBUG;
		return unless $owner;
		$owner->on_service_recv(@_);
	} else {
		TRACE("No task owner - message dropped") if DEBUG;
	}

}


1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
