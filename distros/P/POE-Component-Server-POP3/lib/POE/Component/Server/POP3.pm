package POE::Component::Server::POP3;
$POE::Component::Server::POP3::VERSION = '0.12';
#ABSTRACT: A POE framework for authoring POP3 servers

use strict;
use warnings;
use POE qw(Wheel::SocketFactory Wheel::ReadWrite Filter::Line);
use base qw(POE::Component::Pluggable);
use POE::Component::Pluggable::Constants qw(:ALL);
use Socket;

sub spawn {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  my $options = delete $opts{options};
  $opts{version} = join('-', __PACKAGE__, $POE::Component::Server::POP3::VERSION ) unless $opts{version};
  $opts{handle_connects} = 1 unless defined $opts{handle_connects} and !$opts{handle_connects};
  $opts{hostname} = 'localhost' unless defined $opts{hostname};
  my $self = bless \%opts, $package;
  $self->_pluggable_init( prefix => 'pop3d_', types => [ 'POP3D', 'POP3C' ], debug => 1 );
  $self->{session_id} = POE::Session->create(
	object_states => [
	   $self => { shutdown       => '_shutdown',
		      send_event     => '__send_event',
		      send_to_client => '_send_to_client',
		      disconnect     => '_disconnect',
	            },
	   $self => [ qw(_start register unregister _accept_client _accept_failed _conn_input _conn_error _conn_flushed _conn_alarm _send_to_client __send_event _disconnect) ],
	],
	heap => $self,
	( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub session_id {
  return $_[0]->{session_id};
}

sub getsockname {
  return unless $_[0]->{listener};
  return $_[0]->{listener}->getsockname();
}

sub _conn_exists {
  my ($self,$wheel_id) = @_;
  return 0 unless $wheel_id and defined $self->{clients}->{ $wheel_id };
  return 1;
}

sub _valid_cmd {
  my $self = shift;
  my $cmd = shift || return;
  $cmd = lc $cmd;
  return 0 unless grep { $_ eq $cmd } @{ $self->{cmds} };
  return 1;
}

sub shutdown {
  my $self = shift;
  $poe_kernel->post( $self->{session_id}, 'shutdown' );
}

sub _start {
  my ($kernel,$self,$sender) = @_[KERNEL,OBJECT,SENDER];
  $self->{session_id} = $_[SESSION]->ID();
  if ( $self->{alias} ) {
	$kernel->alias_set( $self->{alias} );
  }
  else {
	$kernel->refcount_increment( $self->{session_id} => __PACKAGE__ );
  }
  if ( $kernel != $sender ) {
    my $sender_id = $sender->ID;
    $self->{events}->{'pop3d_all'}->{$sender_id} = $sender_id;
    $self->{sessions}->{$sender_id}->{'ref'} = $sender_id;
    $kernel->refcount_increment($sender_id, __PACKAGE__);
    $kernel->post( $sender, 'pop3d_registered', $self );
    $kernel->detach_myself();
  }

  $self->{filter} = POE::Filter::Line->new( Literal => "\015\012" );

  $self->{cmds} = [ qw(stat list retr dele noop rset top uidl user pass apop quit) ];

  $self->{listener} = POE::Wheel::SocketFactory->new(
      ( defined $self->{address} ? ( BindAddress => $self->{address} ) : () ),
      ( defined $self->{port} ? ( BindPort => $self->{port} ) : ( BindPort => 110 ) ),
      SuccessEvent   => '_accept_client',
      FailureEvent   => '_accept_failed',
      SocketDomain   => AF_INET,             # Sets the socket() domain
      SocketType     => SOCK_STREAM,         # Sets the socket() type
      SocketProtocol => 'tcp',               # Sets the socket() protocol
      Reuse          => 'on',                # Lets the port be reused
  );

  return;
}

sub _accept_client {
  my ($kernel,$self,$socket,$peeraddr,$peerport) = @_[KERNEL,OBJECT,ARG0..ARG2];
  my $sockaddr = inet_ntoa( ( unpack_sockaddr_in ( CORE::getsockname $socket ) )[1] );
  my $sockport = ( unpack_sockaddr_in ( CORE::getsockname $socket ) )[0];
  $peeraddr = inet_ntoa( $peeraddr );

  my $wheel = POE::Wheel::ReadWrite->new(
	Handle => $socket,
	Filter => $self->{filter},
	InputEvent => '_conn_input',
	ErrorEvent => '_conn_error',
	FlushedEvent => '_conn_flushed',
  );

  return unless $wheel;

  my $id = $wheel->ID();
  $self->{clients}->{ $id } =
  {
				wheel    => $wheel,
				peeraddr => $peeraddr,
				peerport => $peerport,
				sockaddr => $sockaddr,
				sockport => $sockport,
  };
  $self->_send_event( 'pop3d_connection', $id, $peeraddr, $peerport, $sockaddr, $sockport );

  $self->{clients}->{ $id }->{alarm} = $kernel->delay_set( '_conn_alarm', $self->{time_out} || 300, $id );
  return;
}

sub _accept_failed {
  my ($kernel,$self,$operation,$errnum,$errstr,$wheel_id) = @_[KERNEL,OBJECT,ARG0..ARG3];
  warn "Wheel $wheel_id generated $operation error $errnum: $errstr\n";
  delete $self->{listener};
  $self->_send_event( 'pop3d_listener_failed', $operation, $errnum, $errstr );
  return;
}

sub _conn_input {
  my ($kernel,$self,$input,$id) = @_[KERNEL,OBJECT,ARG0,ARG1];
  return unless $self->_conn_exists( $id );
  $kernel->delay_adjust( $self->{clients}->{ $id }->{alarm}, $self->{time_out} || 300 );
  $input =~ s/^\s+//g;
  $input =~ s/\s+$//g;
  my @args = split /\s+/, $input, 2;
  my $cmd = shift @args;
  return unless $cmd;
  unless ( $self->_valid_cmd( $cmd ) ) {
    $self->send_to_client( $id, '-ERR' );
    return;
  }
  $cmd = lc $cmd;
  $self->{clients}->{ $id }->{quit} = 1 if $cmd eq 'quit';
  $self->_send_event( 'pop3d_cmd_' . $cmd, $id, @args );
  return;
}

sub _conn_error {
  my ($self,$errstr,$id) = @_[OBJECT,ARG2,ARG3];
  return unless $self->_conn_exists( $id );
  delete $self->{clients}->{ $id };
  $self->_send_event( 'pop3d_disconnected', $id );
  return;
}

sub _conn_flushed {
  my ($self,$id) = @_[OBJECT,ARG0];
  return unless $self->_conn_exists( $id );
  return unless $self->{clients}->{ $id }->{quit};
  delete $self->{clients}->{ $id };
  $self->_send_event( 'pop3d_disconnected', $id );
  return;
}

sub _conn_alarm {
  my ($kernel,$self,$id) = @_[KERNEL,OBJECT,ARG0];
  return unless $self->_conn_exists( $id );
  delete $self->{clients}->{ $id };
  $self->_send_event( 'pop3d_disconnected', $id );
  return;
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  delete $self->{listener};
  delete $self->{clients};
  $kernel->alarm_remove_all();
  $kernel->alias_remove( $_ ) for $kernel->alias_list();
  $kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ ) unless $self->{alias};
  $self->_pluggable_destroy();
  $self->_unregister_sessions();
  return;
}

sub register {
  my ($kernel, $self, $session, $sender, @events) =
    @_[KERNEL, OBJECT, SESSION, SENDER, ARG0 .. $#_];

  unless (@events) {
    warn "register: Not enough arguments";
    return;
  }

  my $sender_id = $sender->ID();

  foreach (@events) {
    $_ = "pop3d_" . $_ unless /^_/;
    $self->{events}->{$_}->{$sender_id} = $sender_id;
    $self->{sessions}->{$sender_id}->{'ref'} = $sender_id;
    unless ($self->{sessions}->{$sender_id}->{refcnt}++ or $session == $sender) {
      $kernel->refcount_increment($sender_id, __PACKAGE__);
    }
  }

  $kernel->post( $sender, 'pop3d_registered', $self );
  return;
}

sub unregister {
  my ($kernel, $self, $session, $sender, @events) =
    @_[KERNEL,  OBJECT, SESSION,  SENDER,  ARG0 .. $#_];

  unless (@events) {
    warn "unregister: Not enough arguments";
    return;
  }

  $self->_unregister($session,$sender,@events);
  undef;
}

sub _unregister {
  my ($self,$session,$sender) = splice @_,0,3;
  my $sender_id = $sender->ID();

  foreach (@_) {
    $_ = "pop3d_" . $_ unless /^_/;
    my $blah = delete $self->{events}->{$_}->{$sender_id};
    unless ( $blah ) {
	warn "$sender_id hasn't registered for '$_' events\n";
	next;
    }
    if (--$self->{sessions}->{$sender_id}->{refcnt} <= 0) {
      delete $self->{sessions}->{$sender_id};
      unless ($session == $sender) {
        $poe_kernel->refcount_decrement($sender_id, __PACKAGE__);
      }
    }
  }
  undef;
}

sub _unregister_sessions {
  my $self = shift;
  my $pop3d_id = $self->session_id();
  foreach my $session_id ( keys %{ $self->{sessions} } ) {
     if (--$self->{sessions}->{$session_id}->{refcnt} <= 0) {
        delete $self->{sessions}->{$session_id};
	$poe_kernel->refcount_decrement($session_id, __PACKAGE__)
		unless ( $session_id eq $pop3d_id );
     }
  }
}

sub __send_event {
  my( $self, $event, @args ) = @_[ OBJECT, ARG0, ARG1 .. $#_ ];
  $self->_send_event( $event, @args );
  return;
}

sub _pluggable_event {
  my $self = shift;
  $poe_kernel->post( $self->{session_id}, '__send_event', @_ );
}

sub send_event {
  my $self = shift;
  $poe_kernel->post( $self->{session_id}, '__send_event', @_ );
}

sub _send_event  {
  my $self = shift;
  my ($event, @args) = @_;
  my $kernel = $POE::Kernel::poe_kernel;
  my $session = $kernel->get_active_session()->ID();
  my %sessions;

  my @extra_args;

  return 1 if $self->_pluggable_process( 'POP3D', $event, \( @args ), \@extra_args ) == PLUGIN_EAT_ALL;

  push @args, @extra_args if scalar @extra_args;

  $sessions{$_} = $_ for (values %{$self->{events}->{'pop3d_all'}}, values %{$self->{events}->{$event}});

  $kernel->post( $_ => $event => @args ) for values %sessions;
  undef;
}

sub disconnect {
  my $self = shift;
  $poe_kernel->call( $self->{session_id}, '_disconnect', @_ );
}

sub _disconnect {
  my ($kernel,$self,$id) = @_[KERNEL,OBJECT,ARG0];
  return unless $self->_conn_exists( $id );
  $self->{clients}->{ $id }->{quit} = 1;
  return 1;
}

sub send_to_client {
  my $self = shift;
  $poe_kernel->call( $self->{session_id}, '_send_to_client', @_ );
}

sub _send_to_client {
  my ($kernel,$self,$id,$output) = @_[KERNEL,OBJECT,ARG0..ARG1];
  return unless $self->_conn_exists( $id );
  return unless defined $output;

  return 1 if $self->_pluggable_process( 'POP3C', 'response', $id, \$output ) == PLUGIN_EAT_ALL;

  $self->{clients}->{ $id }->{wheel}->put($output);
  return 1;
}

sub POP3D_connection {
  my ($self,$pop3d) = splice @_, 0, 2;
  my $id = ${ $_[0] };
  return PLUGIN_EAT_NONE unless $self->{handle_connects};
  $self->send_to_client( $id, join ' ', '+OK POP3', $self->{hostname}, $self->{version}, 'server ready' );
  return PLUGIN_EAT_NONE;
}

'poppet';

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Server::POP3 - A POE framework for authoring POP3 servers

=head1 VERSION

version 0.12

=head1 SYNOPSIS

  # A simple POP3 Server that demonstrates functionality
  use strict;
  use POE;
  use POE::Component::Server::POP3

  POE::Session->create(
	package_states => [
	  'main' => [qw(
			_start
			pop3d_registered
			pop3d_connection
			pop3d_disconnected
			pop3d_cmd_quit
			pop3d_cmd_user
			pop3d_cmd_pass
			pop3d_cmd_stat
			pop3d_cmd_list
			pop3d_cmd_noop
	  )],
	],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    $_[HEAP]->{pop3d} = POE::Component::Server::POP3->spawn(
	hostname => 'pop.foobar.com',
    );
    return;
  }

  sub pop3d_registered {
    # Successfully started pop3d
    return;
  }

  sub pop3d_connection {
    my ($heap,$id) = @_[HEAP,ARG0];
    $heap->{clients}->{ $id } = { auth => 0 };
    return;
  }

  sub pop3d_disconnected {
    my ($heap,$id) = @_[HEAP,ARG0];
    delete $heap->{clients}->{ $id };
    return;
  }

  sub pop3d_cmd_quit {
    my ($heap,$id) = @_[HEAP,ARG0];
    unless ( $heap->{clients}->{ $id }->{auth} ) {
	$heap->{pop3d}->send_to_client( $id, '+OK POP3 server signing off' );
	return;
    }
    # Process mailbox in some way
    $heap->{pop3d}->send_to_client( $id, '+OK POP3 server signing off' );
    return;
  }

  sub pop3d_cmd_user {
    my ($heap,$id) = @_[HEAP,ARG0];
    my $user = ( split /\s+/, $_[ARG1] )[0];
    unless ( $user ) {
	$heap->{pop3d}->send_to_client( $id, '-ERR Missing username argument' );
	return;
    }
    $heap->{clients}->{ $id }->{user} = $user;
    $heap->{pop3d}->send_to_client( $id, '+OK User name accepted, password please' );
    return;
  }

  sub pop3d_cmd_pass {
    my ($heap,$id) = @_[HEAP,ARG0];
    my $pass = ( split /\s+/, $_[ARG1] )[0];
    unless ( $pass ) {
	$heap->{pop3d}->send_to_client( $id, '-ERR Missing password argument' );
	return;
    }
    $heap->{clients}->{ $id }->{pass} = $pass;
    # Check the password
    $heap->{clients}->{ $id }->{auth} = 1;
    $heap->{pop3d}->send_to_client( $id, '+OK Mailbox open, 0 messages' );
    return;
  }

  sub pop3d_cmd_stat {
    my ($heap,$id) = @_[HEAP,ARG0];
    unless ( $heap->{clients}->{ $id }->{auth} ) {
	$heap->{pop3d}->send_to_client( $id, '-ERR Unknown AUTHORIZATION state command' );
	return;
    }
    $heap->{pop3d}->send_to_client( $id, '+OK 0 0' );
    return;
  }

  sub pop3d_cmd_noop {
    my ($heap,$id) = @_[HEAP,ARG0];
    unless ( $heap->{clients}->{ $id }->{auth} ) {
	$heap->{pop3d}->send_to_client( $id, '-ERR Unknown AUTHORIZATION state command' );
	return;
    }
    $heap->{pop3d}->send_to_client( $id, '+OK No-op to you too!' );
    return;
  }

  sub pop3d_cmd_list {
    my ($heap,$id) = @_[HEAP,ARG0];
    unless ( $heap->{clients}->{ $id }->{auth} ) {
	$heap->{pop3d}->send_to_client( $id, '-ERR Unknown AUTHORIZATION state command' );
	return;
    }
    $heap->{pop3d}->send_to_client( $id, '+OK Mailbox scan listing follows' );
    $heap->{pop3d}->send_to_client( $id, '.' );
    return;
  }

=head1 DESCRIPTION

POE::Component::Server::POP3 is a L<POE> component that provides a framework for 
authoring POP3 L<http://www.faqs.org/rfcs/rfc1939.html> servers with POE.

It creates a listening TCP socket ( by default on port 110 ) and accepts connections from
multiple clients. Each connecting client is assigned a unique ID. 
Input from clients generates events that other POE components and sessions
may register to receive. The POP3 poco also handles sending output to applicable clients.

One may either interface with the component via the POE API or via L<POE::Component::Pluggable> plugins.

=for Pod::Coverage POP3D_connection

=head1 CONSTRUCTOR

=over

=item C<spawn>

Takes a number of optional arguments:

  'alias', set an alias on the component;
  'address', bind the listening socket to a particular address;
  'port', listen on a particular port, default is 110;
  'options', a hashref of POE::Session options;
  'hostname', the name that the server will identify as;
  'version', change the version string reported in initial client connections;
  'handle_connects', set this to a false value to stop the component sending
	initial connection responses to connecting clients;

Returns a POE::Component::Server::POP3 object.

=back

=head1 METHODS

=over

=item C<session_id>

Returns the POE::Session ID of the component.

=item C<shutdown>

Terminates the component. Shuts down the listener and disconnects connected clients.

=item C<send_event>

Sends an event through the component's event handling system.

=item C<send_to_client>

Send some output to a connected client. First parameter must be a valid client id. Second parameter is a string of text to send.

=item C<disconnect>

Places a client connection in pending disconnect state. Requires a valid client ID as a parameter. Set this, then send an applicable message to the client using send_to_client() and the client connection will be terminated.

=item C<getsockname>

Access to the L<POE::Wheel::SocketFactory> method of the underlying listening socket.

=back

=head1 INPUT EVENTS

These are events that the component will accept:

=over

=item C<register>

Takes N arguments: a list of event names that your session wants to listen for, minus the 'pop3d_' prefix, ( this is 
similar to L<POE::Component::IRC> ). 

Registering for C<all> will cause it to send all POP3D-related events to you; this is the easiest way to handle it.

=item C<unregister>

Takes N arguments: a list of event names which you don't want to receive. If you've previously done a 'register' for a particular event which you no longer care about, this event will tell the POP3D to stop sending them to you. (If you haven't, it just ignores you. No big deal).

=item C<shutdown>

Terminates the component. Shuts down the listener and disconnects connected clients.

=item C<send_event>

Sends an event through the component's event handling system. 

=item C<send_to_client>

Send some output to a connected client. First parameter must be a valid client ID. 
Second parameter is a string of text to send.

=item C<disconnect>

Places a client connection in pending disconnect state. Requires a valid client ID as a parameter. Set this, then send an applicable message to the client using send_to_client() and the client connection will be terminated.

=back

=head1 OUTPUT EVENTS

The component sends the following events to registered sessions:

=over

=item C<pop3d_registered>

This event is sent to a registering session. ARG0 is the POE::Component::Server::POP3
object.

=item C<pop3d_listener_failed>

Generated if the component cannot either start a listener or there is a problem
accepting client connections. ARG0 contains the name of the operation that failed. 
ARG1 and ARG2 hold numeric and string values for $!, respectively.

=item C<pop3d_connection>

Generated whenever a client connects to the component. ARG0 is the client ID, ARG1
is the client's IP address, ARG2 is the client's TCP port. ARG3 is our IP address and
ARG4 is our socket port.

If 'handle_connects' is true ( which is the default ), the component will automatically
send an initial connection response to the client.

=item C<pop3d_disconnected>

Generated whenever a client disconnects. ARG0 is the client ID.

=item C<pop3d_cmd_*>

Generated for each POP3 command that a connected client sends to us. ARG0 is the 
client ID. ARG1 .. ARGn are any parameters that are sent with the command. Check 
the RFC L<http://www.faqs.org/rfcs/rfc1939.html> for details.

=back

=head1 PLUGINS

POE::Component::Server::POP3 utilises L<POE::Component::Pluggable> to enable a
L<POE::Component::IRC> type plugin system. 

=head2 PLUGIN HANDLER TYPES

There are two types of handlers that can registered for by plugins, these are 

=over

=item C<POP3D>

These are the 'pop3d_' prefixed events that are generated. In a handler arguments are
passed as scalar refs so that you may mangle the values if required.

=item C<POP3C>

These are generated whenever a response is sent to a client. Again, any 
arguments passed are scalar refs for manglement. There is really on one type
of this handler generated 'POP3C_response'

=back

=head2 PLUGIN EXIT CODES

Plugin handlers should return a particular value depending on what action they wish
to happen to the event. These values are available as constants which you can use 
with the following line:

  use POE::Component::Server::POP3::Constants qw(:ALL);

The return values have the following significance:

=over

=item C<POP3D_EAT_NONE>

This means the event will continue to be processed by remaining plugins and
finally, sent to interested sessions that registered for it.

=item C<POP3D_EAT_CLIENT>

This means the event will continue to be processed by remaining plugins but
it will not be sent to any sessions that registered for it. This means nothing
will be sent out on the wire if it was an POP3C event, beware!

=item C<POP3D_EAT_PLUGIN>

This means the event will not be processed by remaining plugins, it will go
straight to interested sessions.

=item C<POP3D_EAT_ALL>

This means the event will be completely discarded, no plugin or session will see it. This
means nothing will be sent out on the wire if it was an POP3C event, beware!

=back

=head2 PLUGIN METHODS

The following methods are available:

=over

=item C<pipeline>

Returns the L<POE::Component::Pluggable::Pipeline> object.

=item C<plugin_add>

Accepts two arguments:

  The alias for the plugin
  The actual plugin object

The alias is there for the user to refer to it, as it is possible to have multiple
plugins of the same kind active in one POE::Component::Server::POP3 object.

This method goes through the pipeline's push() method.

 This method will call $plugin->plugin_register( $pop3d )

Returns the number of plugins now in the pipeline if plugin was initialized, undef
if not.

=item C<plugin_del>

Accepts one argument:

  The alias for the plugin or the plugin object itself

This method goes through the pipeline's remove() method.

This method will call $plugin->plugin_unregister( $pop3d )

Returns the plugin object if the plugin was removed, undef if not.

=item C<plugin_get>

Accepts one argument:

  The alias for the plugin

This method goes through the pipeline's get() method.

Returns the plugin object if it was found, undef if not.

=item C<plugin_list>

Has no arguments.

Returns a hashref of plugin objects, keyed on alias, or an empty list if there are no
plugins loaded.

=item C<plugin_order>

Has no arguments.

Returns an arrayref of plugin objects, in the order which they are encountered in the
pipeline.

=item C<plugin_register>

Accepts the following arguments:

  The plugin object
  The type of the hook, POP3D or POP3C
  The event name(s) to watch

The event names can be as many as possible, or an arrayref. They correspond
to the prefixed events and naturally, arbitrary events too.

You do not need to supply events with the prefix in front of them, just the names.

It is possible to register for all events by specifying 'all' as an event.

Returns 1 if everything checked out fine, undef if something's seriously wrong

=item C<plugin_unregister>

Accepts the following arguments:

  The plugin object
  The type of the hook, pop3D or POP3C
  The event name(s) to unwatch

The event names can be as many as possible, or an arrayref. They correspond
to the prefixed events and naturally, arbitrary events too.

You do not need to supply events with the prefix in front of them, just the names.

It is possible to register for all events by specifying 'all' as an event.

Returns 1 if all the event name(s) was unregistered, undef if some was not found.

=back

=head2 PLUGIN TEMPLATE

The basic anatomy of a plugin is:

        package Plugin;

        # Import the constants, of course you could provide your own 
        # constants as long as they map correctly.
        use POE::Component::Server::POP3::Constants qw( :ALL );

        # Our constructor
        sub new {
                ...
        }

        # Required entry point for plugins
        sub plugin_register {
                my( $self, $pop3d ) = @_;

                # Register events we are interested in
                $pop3d->plugin_register( $self, 'POP3D', qw(all) );

                # Return success
                return 1;
        }

        # Required exit point for pluggable
        sub plugin_unregister {
                my( $self, $pop3d ) = @_;

                # Pluggable will automatically unregister events for the plugin

                # Do some cleanup...

                # Return success
                return 1;
        }

        sub _default {
                my( $self, $pop3d, $event ) = splice @_, 0, 3;

                print "Default called for $event\n";

                # Return an exit code
                return POP3D_EAT_NONE;
        }

=head1 SEE ALSO

L<POE::Component::Pluggable>

RFC 1939 L<http://www.faqs.org/rfcs/rfc1939.html>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
