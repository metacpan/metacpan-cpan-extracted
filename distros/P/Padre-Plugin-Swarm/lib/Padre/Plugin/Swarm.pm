package Padre::Plugin::Swarm;
use 5.008;
use strict;
use warnings;
use Socket;
use IO::Handle;
use File::Spec        ();
use Padre::Constant   ();
use Padre::Role::Task ();
use Padre::Wx         ();
use Padre::Plugin     ();
use Object::Event     ();
use Padre::Wx::Icon   ();
use Padre::Logger;
use Params::Util '_INVOCANT';
use Carp 'confess';
use Data::Dumper;

our $VERSION = '0.2';
our @ISA     = ('Padre::Plugin','Padre::Role::Task','Object::Event');

sub padre_interfaces {
	#'Padre::Task' 		=> 0.90,
	#'Padre::Document' 	=> 0.91,
	#'Padre::Plugin' 	=> 0.91,
}

use Class::XSAccessor {
	accessors => {
		config    => 'config',
		wx        => 'wx',
		global    => 'global',
		local     => 'local',
		service   => 'service',
	}
};

# TODO connect/disconnect should be ->enable and ->disable
sub connect {
	my $self = shift;
	$self->global->event('enable');
	$self->local->event('enable');
	return;
}

sub disconnect {
	my $self = shift;


	$self->global->event('disable');
	$self->local->event('disable');
	
	# Don't rely on Task bi-directional
	#$self->service->tell_child( 'shutdown_service' => "disabled" );
	
	# Co-operative shutdown the service, allowing Task->run to complete in the child
	$self->service->notify( 'shutdown_service'  , 'disabled' );
	return;
	
}


## Task::Role handlers for subscribed states of the child task/service
sub on_swarm_service_message {
	my $self = shift;
	my $service = shift;
	my $incoming= shift;
	
	# Puke about this as ': shared' should only be applied to the storable data
	#  as it is moved between threads. Decoded message should NOT be :shared
	if ( threads::shared::is_shared( $incoming ) ) {
		TRACE('Parent RECV : shared ??? ' . Dumper $incoming );
		confess 'got : shared $message';
	}

	if (ref $incoming eq 'ARRAY') {
		# Enveloped messages from the service are 'events'
		my ($eventname,@args) = @$incoming;
		TRACE( 'Posting Service event ' . $eventname ) if DEBUG;
		$self->event($eventname,@args);
		return;
	} elsif ( _INVOCANT($incoming) ) {  # TODO be more explicit about INVOCANT
		# This still seems to result in editor flicker?
		my $lock = $self->main->lock('UPDATE');
		
		my $origin  = $incoming->origin;
		$self->event( "recv_$origin" , $incoming );
	}
	
	return;
}

sub on_swarm_service_running {
	my ($self,$service) = @_;
	# Capture the service. We're not CONNECTED yet - the service is just running
	$self->{service} = $service;
	return;
}

sub on_swarm_service_finish {
	TRACE( "Service finished?? @_" ) if DEBUG;
	my $self = shift;
	# In theory we're already disconnected
	# just cleanup the finished task
	delete $self->{service};
	return;
}


sub on_swarm_service_status {
	TRACE( @_ )  if DEBUG;
	my $self = shift;
	$self->main->status(shift);
}


# Surely Padre::Role::Task would provide this?
# TODO - investigate a way to have Service co-operatively exit it's loop
sub task_cancel {
	my $self = shift;
	$self->task_manager->cancel( $self->{task_revision} );
}



SCOPE: {
# This is here to cheat and presume transports will connect - eventually.
# accept ->send from the foreground and queue it until the service is 
# running and connected;
my @outbox;

sub _flush_outbox {
	my ($self,$origin) = @_;
	my @list = grep { $_->[0] eq $origin } @outbox;
	my @keep = grep { $_->[0] ne $origin } @outbox;
	@outbox = @keep;
	$self->send(@$_) for @list;
	return;
}

sub send {
	my ($self,$origin,$message) = @_;
	my $service = $self->{service};
	
	TRACE( 'Sending to task ~ ' . $service ) if DEBUG;
	# Be careful - we can race our task and send messages to it before it is ready
	unless ($self->{service}) {
		TRACE( "Queued service message in outbox" ) if DEBUG;
		push @outbox, [$origin,$message];
		return;
	}
	
	my $handler = 'send_'.$origin;
	TRACE( "outbound handle $handler" ) if DEBUG;
	$self->{service}->notify( $handler => $message );

}

}
# END SCOPE:


# TODO move identity management into the ::Universe
sub identity {
	my $self = shift;
	unless ($self->{identity}) {
		my $config = Padre::Config->read;
		# Default to your padre nickname.
		my $nickname = $config->identity_nickname;
		#my $id = $$ . time(). $config . $self;

		unless ( $nickname ) {
			$nickname = "Anonymous_$$";
		}
		$self->{identity} =
			Padre::Swarm::Identity->new(
				nickname => $nickname,
				service => 'swarm',
			);
	}
	return $self->{identity};
}








#####################################################################
# Padre::Plugin Methods

sub plugin_name {
	'Swarm';
}

sub plugin_icons_directory {
	my $dir = File::Spec->catdir(
		shift->plugin_directory_share(@_),
		'icons',
	);
	$dir;
}

sub plugin_icon {
	my $class = shift;
	Padre::Wx::Icon::find(
		'status/padre-plugin-swarm',
		{ icons => $class->plugin_icons_directory },
	);
}

sub plugin_large_icon {
	my $class = shift;
	my $icon  = Padre::Wx::Icon::find(
		'status/padre-plugin-swarm',
		{
			size  => '128x128',
			icons => $class->plugin_icons_directory,
		}
	);
	return $icon;
}

sub margin_icons {
	my $class = shift;
	my $icon1  = Padre::Wx::Icon::find(
		'margin/ghost-one',
		{
			size  => '12x12',
			icons => $class->plugin_icons_directory,
		}
	);
	my $icon2  = Padre::Wx::Icon::find(
		'margin/ghost-two',
		{
			size  => '12x12',
			icons => $class->plugin_icons_directory,
		}
	);
	
	return ($icon1,$icon2);
}

sub margin_owner_icons {
	my $class = shift;
	my $icon1  = Padre::Wx::Icon::find(
		'margin/owner-one',
		{
			size  => '12x12',
			icons => $class->plugin_icons_directory,
		}
	);
	my $icon2  = Padre::Wx::Icon::find(
		'margin/owner-two',
		{
			size  => '12x12',
			icons => $class->plugin_icons_directory,
		}
	);
	
	return ($icon1,$icon2);
}

sub margin_feedback_icon {
	my $class = shift;
	my $icon = Padre::Wx::Icon::find(
		'margin/feedback',
		{
			size  => '12x12',
			icons => $class->plugin_icons_directory,
		}
	);
	warn "Got icon $icon";
	return $icon;
}

sub menu_plugins_simple {
    my $self = shift;
    return $self->plugin_name => [
        'About' => sub { $self->show_about },
    ];
}

# Singleton (I think)
SCOPE: {
	my $instance;

	sub new {
		die "Plugin instance is still defined - cannot create a new one"
			if $instance;
		
		$instance = shift->SUPER::new(@_);
	}

	sub instance { $instance };

	sub plugin_enable {
		my $self   = shift;
		# TODO - enforce singleton!!
		$instance  = $self;
		my $wxobj = new Wx::Panel $self->main;
		$self->wx( $wxobj );
		$wxobj->Hide;
		
		Wx::Image::AddHandler( Wx::XPMHandler->new );


		require Padre::Plugin::Swarm::Service;
		require Padre::Plugin::Swarm::Wx::Preferences;
		require Padre::Plugin::Swarm::Universe;
		require Padre::Swarm::Geometry;

		my $config = $self->bootstrap_config;
		$self->config( $config );

		my $u_global = 	Padre::Plugin::Swarm::Universe->new(origin=>'global');
		my $u_local  = 	Padre::Plugin::Swarm::Universe->new(origin=>'local');
		
		$self->global($u_global);
		$self->local($u_local);
		
		$self->task_request(
				task =>'Padre::Plugin::Swarm::Service',
					on_message => 'on_swarm_service_message',
					on_finish  => 'on_swarm_service_finish',
					on_run     => 'on_swarm_service_running',
					on_status  => 'on_swarm_service_status',
		);
		$self->reg_cb( 'connect' , \&event_connect );
		$self->reg_cb( 'disconnect', \&event_disconnect );
		$self->connect();


		1;
	}

	sub plugin_disable {
		my $self = shift;

		# TODO - is this being used at ALL ?
		$self->wx->Destroy;
		$self->wx(undef);
		
		$self->disconnect;
		
		undef $instance;


	}
} # END SCOPE

sub plugin_preferences {
	my $self = shift;
	my $wx = shift;
	if  ( $self->instance ) {
		die "Please disable plugin before editing preferences\n";

	}
	eval {
		my $dialog = Padre::Plugin::Swarm::Wx::Preferences->new($wx);
		$dialog->ShowModal;
		$dialog->Destroy;
	};

	TRACE( "Preferences error $@" ) if DEBUG && $@;

	return;
}

sub bootstrap_config {
	my $self = shift;
	my $config = $self->config_read;
	@$config{qw/
		nickname
		token
		transport
		local_multicast
		global_server
		bootstrap
	/} = (
		'Anonymous_'.$$,
		crypt ( rand().$$.time, 'swarm' ) ,
		'global',
		'239.255.255.1',
		'swarm.perlide.org',
		$VERSION
		) ;

	$self->config_write( $config );
	return $config;

}


# Catch notification from Padre and rethrow events for them.
sub editor_enable {
	my $self = shift;
	$self->event( 'editor_enable' , @_ );
}

sub editor_disable {
	my $self = shift;
	$self->event( 'editor_disable' , @_ );
}


sub show_about {
	my $self = shift;

	# Generate the About dialog
	my $icon  = Padre::Wx::Icon::find(
		'status/padre-plugin-swarm',
		{
			size  => '128x128',
			icons => $self->plugin_icons_directory,
		}
	);

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName('Swarm Plugin');
	$about->SetDescription( <<"END_MESSAGE" );
Surrender to the Swarm!
END_MESSAGE
	$about->SetIcon( Padre::Wx::Icon::cast_to_icon($icon) );
	# Show the About dialog
	Wx::AboutBox($about);

	return;
}


# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

1;

__END__

=pod

=head1 NAME

Padre::Plugin::Swarm - Experimental plugin for co-operative editing

=head1 DESCRIPTION

This is Swarm!

Swarm is a Padre plugin for experimenting with remote inspection,
peer programming and co-operative editing functionality.

Within this plugin all rules are suspended. No security, no efficiency,
no scalability, no standards compliance, remote code execution,
everything is allowed. The only goal is things that work, and things
that look shiny in a demo :)

B<Addendum> Deliberate remote code execution was 
removed very early. Swarm no longer blindly runs code sent to it from the network.

=head1 FEATURES

=head2 Connectivity

=over

=item * 

Global server transport - Connect with other Swarmers on teh interwebs. 
C<swarm.perlide.org> is a free swarm server

=item *

Local network multicast transport. Connect with Swarmers on your 
local network. No configuration required - other editors should simply 'appear'

=back

=head2 Interfaces

=over
    
=item *

L<User chat|Padre::Plugin::Swarm::Wx::Chat> 
- converse with other padre editors

=item *

Resources - browse and open files from another users' editor

=item *

L<Editor|Padre::Plugin::Swarm::Wx::Editor>
integration and co-operation allow multiple users to edit the same document
at the same time.

=back

=head1 SEE ALSO

L<Padre::Swarm::Manual> L<Padre::Plugin::Swarm::Wx::Chat>
L<Padre::Plugin::Swarm::Wx::Editor>

=head1 BUGS

  Many. Identity management and interaction with L<Padre::Swarm::Geometry> is
  rather poor.

  More than 2 users editing same document at once MAY not work
  
  No accomodation is made for edits that overlap in time spent transmitting
  them. Edits MAY arrive out of order.

=head1 COPYRIGHT

Copyright 2009-2011 The Padre development team as listed in Padre.pm

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
