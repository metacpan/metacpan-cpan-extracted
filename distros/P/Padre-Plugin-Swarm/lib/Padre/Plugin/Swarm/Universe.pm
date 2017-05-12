package Padre::Plugin::Swarm::Universe;
use strict;
use warnings;
use Padre::Logger;
use Class::XSAccessor 
	accessors => {
		token => 'token',
		resources => 'resources',
		origin => 'origin',
		chat => 'chat',
		geometry => 'geometry',
		transport => 'transport',
		editor => 'editor',
		label =>'label',
	};

use base qw( Object::Event );
use Data::Dumper;

use Padre::Plugin::Swarm::Wx::Chat;
use Padre::Plugin::Swarm::Wx::Editor;
use Padre::Plugin::Swarm::Wx::Resources;
use Padre::Swarm::Geometry;


sub components {
	qw( geometry chat resources editor )
}

sub new {
	my $class = shift;
	my %args = @_;
	
	my $self = $class->SUPER::new(%args);
	my $rself = $self;

	
	my $origin = $self->origin;
	my $plugin = Padre::Plugin::Swarm->instance;
	
	$self->reg_cb( "recv" , \&on_recv );
	$self->plugin->reg_cb( "recv_$origin" , sub { shift; $self->event('recv',@_) } );
	
	$self->reg_cb( "connect" , \&on_connect);
	$self->plugin->reg_cb("connect_$origin", sub{ shift; $self->event('connect',@_)} );
	
	$self->reg_cb( "disconnect", \&on_disconnect );
	$self->plugin->reg_cb("disconnect_$origin", sub{ shift; $self->event('disconnect',@_)} );
	
	## Padre events from plugin - rethrow
	$self->plugin->reg_cb( 
		"editor_enable",
		sub {shift; $self->event('editor_enable', @_ ) }
	);
	$self->plugin->reg_cb( 
		"editor_disable",
		sub {shift; $self->event('editor_disable', @_ ) }
	);
	
	$self->chat(
		new Padre::Plugin::Swarm::Wx::Chat
				universe => $self,
				label => ucfirst( $origin ),
	);
	
	$self->geometry(
		new Padre::Swarm::Geometry
				
	);
	
	
	$self->editor(
		new Padre::Plugin::Swarm::Wx::Editor
				universe => $self,
	);
	# 
	$self->resources(
		Padre::Plugin::Swarm::Wx::Resources->new(
				universe => $self,
				label => ucfirst( $origin )
		)
	);
	
	Scalar::Util::weaken( $self );
	
	return $rself;
}

sub plugin { Padre::Plugin::Swarm->instance };

sub enable {
	my $self = shift;
	$self->event('enable');
}

sub disable { 
	my $self = shift;
	$self->event('disable');
}

sub send {
	my $self    = shift;
	my $message = (@_ == 1) ? shift : { @_ };
	
	TRACE( Dumper $message ) if DEBUG;
	$message->{from} = $self->plugin->identity->nickname;
	
	Padre::Plugin::Swarm->instance->send( $self->origin , $message );
}

sub on_recv {
	my $self = shift;
	TRACE( @_ ) if DEBUG;;
	$self->_notify( 'on_recv' , @_ );
}

sub on_connect {
	my ($self,$token) = @_;
	TRACE( "Swarm transport connected", @_ ) if DEBUG;
	$self->{token} = $token;
	$self->plugin->_flush_outbox($self->origin);
	$self->send(
		{ type=>'announce', service=>'swarm' }
	);
	$self->send(
		{ type=>'disco', service=>'swarm' }
	);
	
	#$self->_notify( 'on_connect', @_ );
	
	return;
}


sub on_disconnect {
	my $self = shift;
	TRACE( "Swarm transport disconnected" ) if DEBUG;
	
	#$self->_notify('on_connect', @_ );
	
}


use Params::Util '_INVOCANT';
use Carp 'confess';
use Data::Dumper;

sub _notify {
	my $self = shift;
	my $notify = shift;
	my $message= $_[0];

	unless ( _INVOCANT($message) ) {
		confess 'unblessed message', Dumper \@_;
		
	}
	if ($message->{token} eq $self->{token}) {
		$message->{is_loopback} = 1;
	} else {
		$message->{is_loopback} = 0;
	}
	my $lock = Padre::Current->main->lock('UPDATE');
	foreach my $c ( $self->components ) {
		my $component = $self->$c;
		unless ( $component ) {
			TRACE( "$notify not handled by component $c" );
			next;
		}

		TRACE( "Notify $component -> $notify with @_" ) if DEBUG;
		eval {
			$component->$notify(@_) if $component->can($notify);
		};
		if ($@) {
			TRACE( "Failed to notify component '$c' , $@" );# $if DEBUG
		}
	}
	return;
}



1;