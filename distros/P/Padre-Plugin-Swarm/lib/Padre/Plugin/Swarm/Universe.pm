package Padre::Plugin::Swarm::Universe;

use strict;
use warnings;
use Padre::Logger;
use Class::XSAccessor 
	accessors => {
		resources => 'resources',
		chat => 'chat',
		geometry => 'geometry',
		transport => 'transport',
		editor => 'editor',
		label =>'label',
	};

sub components {
	qw( geometry chat resources  editor )
}

sub new {
	my $class = shift;
	my $self = bless { @_ },  ref($class) || $class;
	return $self;
}

sub plugin { Padre::Plugin::Swarm->instance };

sub enable {
	my $self = shift;
	if ($self->transport) {
		$self->transport->on_connect(
				sub { $self->on_connect(@_) }
		);
		$self->transport->on_disconnect(
				sub { $self->on_disconnect(@_) }
		);
		$self->transport->on_recv(
				sub { $self->on_recv(@_) }
		);
		
		$self->transport->enable;
	}
	foreach my $c ( $self->components ) {
		$self->$c->enable if $self->$c;
	}
	
	
	
}

sub disable { 
	my $self = shift;

	foreach my $c ( $self->components ) {
		$self->$c->disable if $self->$c;
	}
	$self->transport->disable if $self->transport;
}


sub on_recv {
	my $self = shift;
	$self->_notify( 'on_recv' , @_ );
}

sub on_connect {
	my ($self) = shift;
	TRACE( "Swarm transport connected" ) if DEBUG;
	$self->transport->send(
		{ type=>'announce', service=>'swarm' }
	);
	$self->transport->send(
		{ type=>'disco', service=>'swarm' }
	);
	
	$self->_notify( 'on_connect', @_ );
	
	return;
}


sub on_disconnect {
	my $self = shift;
	TRACE( "Swarm transport disconnected" ) if DEBUG;
	
	$self->_notify('on_connect', @_ );
	
}

sub _notify {
	my $self = shift;
	my $notify = shift;
	my $lock = Padre::Current->main->lock('UPDATE');
	foreach my $c ( $self->components ) {
		my $component = $self->$c;
		next unless $component;
		TRACE( "Notify $component with @_" ) if DEBUG;
		eval {
			$component->$notify(@_) if $component->can($notify);
		};
		if ($@) {
			TRACE( "Failed to notify component '$c' , $@") if DEBUG
		}
	}
	return;
}



1;