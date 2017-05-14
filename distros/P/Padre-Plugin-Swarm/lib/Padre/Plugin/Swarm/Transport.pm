package Padre::Plugin::Swarm::Transport;
use strict;
use warnings;
use Padre::Logger;
use JSON::PP;

use Class::XSAccessor
		accessors => {
			marshal => 'marshal',
			on_connect => 'on_connect',
			on_disconnect => 'on_disconnect',
			on_recv => 'on_recv',
		};

sub new {
	my $class = shift;
	my %args = @_;
	$args{marshal} ||= $class->_marshal;
	my $self = bless \%args, $class;
	my $message_event  = Wx::NewEventType;
	$self->{message_event} = $message_event;
	return $self;
}

sub plugin { Padre::Plugin::Swarm->instance }

sub identity { Padre::Plugin::Swarm->instance->identity }

sub loopback { 0 }

sub token { $_[0]->{token} }

sub message_event { $_[0]->{message_event} }

sub send {
	my $self = shift;
	my $message = shift;
	my $mclass = ref $message;
	unless ( $mclass =~ /^Padre::Swarm::Message/ ) {
		bless $message , 'Padre::Swarm::Message';
	}
	$message->{from} ||= $self->identity->nickname;
	$message->{token} ||= $self->token;
	
	my $data = eval { $self->marshal->encode( $message ) };
	if ($data) {
		$self->write($data);
		$self->on_recv->($message)
			if $self->on_recv && $self->loopback;
		TRACE( "Sent message " . $message->type ) if DEBUG;
	}
	else {
		TRACE( "Failed to encode message - $@" ) if DEBUG;
	}
	
}

sub _marshal {
	JSON::PP->new
	    ->allow_blessed
            ->convert_blessed
            ->utf8
            ->filter_json_object(\&synthetic_class );
}


sub synthetic_class {
	my $var = shift ;
	if ( exists $var->{__origin_class} ) {
		my $stub = $var->{__origin_class};
		my $msg_class = 'Padre::Swarm::Message::' . $stub;
		my $instance = bless $var , $msg_class;
		return $instance;
	} else {
		return bless $var , 'Padre::Swarm::Message';
	}
};

1;