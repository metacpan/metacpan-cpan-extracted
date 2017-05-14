package Padre::Plugin::Swarm;

use 5.008;
use strict;
use warnings;
use File::Spec      ();
use Padre::Constant ();
use Padre::Wx       ();
use Padre::Plugin   ();
use Padre::Wx::Icon ();
use Padre::Logger;

our $VERSION = '0.11';
our @ISA     = 'Padre::Plugin';

use Class::XSAccessor {
	accessors => {
		geometry  => 'geometry',
		resources => 'resources',
		editor    => 'editor',
		chat      => 'chat',
		config    => 'config',
		wx        => 'wx',
		global    => 'global',
		local     => 'local',
	}
};

sub connect {
	my $self = shift;

	# For now - use global,
	#  could be Padre::Plugin::Swarm::Transport::Local::Multicast
	#   based on preferences
	$self->global->enable;
	$self->local->enable;
}

sub disconnect {
	my $self = shift;

	$self->global->disable;
	$self->local->disable;
}

sub NOTsend {
	my $self = shift;
	my $message = shift;
	my $mclass = ref $message;
	unless ( $mclass =~ /^Padre::Swarm::Message/ ) {
		bless $message , 'Padre::Swarm::Message';
	}
	$message->{from} = $self->identity->nickname;
	$self->transport->send( $message );
}

sub on_transport_connect {
	my ($self) = @_;
	TRACE( "Swarm transport connected" ) if DEBUG;
	$self->send(
		{ type=>'announce', service=>'swarm' }
	);
	$self->send(
		{ type=>'disco', service=>'swarm' }
	);
	return;
}

sub on_transport_disconnect {
	my ($self) = @_;
	TRACE( "Swarm transport disconnected" ) if DEBUG;
	$self->chat->write_unstyled( "swarm transport disconnected!\n" );

}

sub on_recv {
	my $self = shift;
	# my $universe = shift;
	my $message = shift;

	TRACE( "on_recv handler for " . $message->type ) if DEBUG;
	# TODO can i use 'SWARM' instead?
	my $lock = $self->main->lock('UPDATE');
	my $handler = 'accept_' . $message->type;

	if ( $self->can( $handler ) ) {
		TRACE( $handler ) if DEBUG;
		eval { $self->$handler( $message ); };
	}

	# TODO - make these parts use the message event! srsly
	$self->geometry->On_SwarmMessage( $message );

	my $data = Storable::freeze( $message );
	Wx::PostEvent(
                $self->wx,
                Wx::PlThreadEvent->new( -1, $self->message_event , $data ),
        ) if $self->message_event;
}

sub accept_disco {
	my ($self,$message) = @_;
	$self->send( {type=>'promote',service=>'swarm'} );
}



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

sub padre_interfaces {
	'Padre::Plugin' => 0.56;
}

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

		require Padre::Plugin::Swarm::Wx::Chat;
		require Padre::Plugin::Swarm::Wx::Resources;
		require Padre::Plugin::Swarm::Wx::Editor;
		require Padre::Plugin::Swarm::Wx::Preferences;
		require Padre::Plugin::Swarm::Transport::Global::WxSocket;
		require Padre::Plugin::Swarm::Transport::Local::Multicast;
		require Padre::Plugin::Swarm::Universe;
		require Padre::Swarm::Geometry;

		my $config = $self->bootstrap_config;
		$self->config( $config );

		my $geo = Padre::Swarm::Geometry->new;
		$self->geometry( $geo );

		my $u_global = Padre::Plugin::Swarm::Universe->new;
		my $u_local  = Padre::Plugin::Swarm::Universe->new;
		$self->global($u_global);
		$self->local($u_local);

		## Instance the transport but do not connect them - yet
		my $t_global =
		Padre::Plugin::Swarm::Transport::Global::WxSocket->new(
			token => $self->config->{token},
			wx => $self->wx,
		);
		$u_global->transport($t_global);

		my $t_local =
			Padre::Plugin::Swarm::Transport::Local::Multicast->new(
				token => $self->config->{token},
				wx    => $self->wx,
			);
		$u_local->transport($t_local);


		$u_global->geometry($geo);
		$u_local->geometry($geo);

		## Should this be in global or local?
		my $editor = Padre::Plugin::Swarm::Wx::Editor->new(
			transport => $t_global,
		);
		$self->editor($editor);
		$u_global->editor($editor);

		my $g_directory = Padre::Plugin::Swarm::Wx::Resources->new(
			$self->main,
			label => 'Global'
		);
		$self->resources( $g_directory );
		$u_global->resources($g_directory);

		my $g_chat = Padre::Plugin::Swarm::Wx::Chat->new( $self->main,
				label => 'Global', transport => $self->global->transport
		 );
		$u_global->chat($g_chat);

		my $l_chat = Padre::Plugin::Swarm::Wx::Chat->new(
				$self->main,
				label => 'Local',
				transport => $self->local->transport
		 );
		$u_local->chat($l_chat);


		$self->connect();


		1;
	}

	sub plugin_disable {
		my $self = shift;

		eval {
				$self->global->disable;
		};
		if ($@) {
			TRACE( "Disable global failed $@" ) if DEBUG;
		}

		eval { $self->local->disable; };
		if ($@) {
			TRACE( "Disable local failed $@" ) if DEBUG;
		}

		$self->editor->disable;
		$self->editor(undef);

		$self->wx->Destroy;
		$self->wx(undef);

		undef $instance;


	}
}

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
	#warn 'Got ' , join "\t" , %$config;
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

sub editor_enable {
	my $self = shift;
	$self->editor->editor_enable(@_);
}

sub editor_disable {
	my $self = shift;
	$self->editor->editor_disable(@_);
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

Padre::Plugin::Swarm - Experimental plugin for collaborative editing

=head1 DESCRIPTION

This is Swarm!

Swarm is a Padre plugin for experimenting with remote inspection,
peer programming and collaborative editing functionality.

Within this plugin all rules are suspended. No security, no efficiency,
no scalability, no standards compliance, remote code execution,
everything is allowed. The only goal is things that work, and things
that look shiny in a demo :)

Lessons learned here will be applied to more practical plugins later.

=head1 FEATURES

=over

=item Global server transport

=item Local network multicast transport.

=item L<User chat|Padre::Plugin::Swarm::Wx::Chat> - converse with other padre editors

=item Resources - browse and open files from other users' editor

=item Remote execution! Run arbitary code in other users' editor

=back

=head1 SEE ALSO

L<Padre::Swarm::Manual> L<Padre::Plugin::Swarm::Wx::Chat>

=head1 BUGS

Many. Identity management and interaction with L<Padre::Swarm::Geometry> is
rather poor.

Crashes when 'Reload All Plugins' is called from the padre plugin manager


=head1 COPYRIGHT

Copyright 2009-2010 The Padre development team as listed in Padre.pm

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
