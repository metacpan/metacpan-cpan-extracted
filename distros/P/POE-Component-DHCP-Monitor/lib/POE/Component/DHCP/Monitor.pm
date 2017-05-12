package POE::Component::DHCP::Monitor;
{
  $POE::Component::DHCP::Monitor::VERSION = '1.04';
}

#ABSTRACT: A simple POE Component for monitoring DHCP traffic.

use strict;
use warnings;
use POE qw(Wheel::SocketFactory);
use Net::DHCP::Packet;
use Socket;

sub spawn {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  $opts{prefix} = 'dhcp_monitor_' unless $opts{prefix};
  $opts{port1} = $opts{port};
  $opts{prefix} .= '_' unless $opts{prefix} =~ /\_$/;
  my $options = delete $opts{options};
  my $self = bless \%opts, $package;
  $self->{session_id} = POE::Session->create(
	object_states => [
	    $self => { shutdown => '_shutdown', },
	    $self => [qw(_start _sock_err _sock_up _sock_err2 _sock_up2 _dhcp_read register unregister)],
	],
	heap => $self,
	( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub getsockname {
  my $self = shift;
  return unless $self->{socket};
  return CORE::getsockname( $self->{socket} );
}

sub getsockname2 {
  my $self = shift;
  return unless $self->{socket2};
  return CORE::getsockname( $self->{socket2} );
}

sub session_id {
  my $self = shift;
  return $self->{session_id};
}

sub shutdown {
  my $self = shift;
  $poe_kernel->post( $self->{session_id}, 'shutdown', @_ );
}

sub _send_event {
  my ($self,$event,@args) = @_;
  $poe_kernel->post( $_ => $event, @args ) for  keys % { $self->{sessions} };
  return 1;
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
    $self->{sessions}->{ $sender->ID }++;
    #$kernel->refcount_increment( $sender->ID, __PACKAGE__ );
    $kernel->post( $sender => $self->{prefix} . 'registered' => $self );
  }

  $self->{factory} = POE::Wheel::SocketFactory->new(
        SocketProtocol => 'udp',
        BindPort       => ( defined $self->{port1} ? $self->{port1} : 67 ),
        SuccessEvent   => '_sock_up',
        FailureEvent   => '_sock_err',
	($self->{address} ?
	       (BindAddress => $self->{address}) : ()),
  );

  $self->{factory2} = POE::Wheel::SocketFactory->new(
        SocketProtocol => 'udp',
        BindPort       => ( defined $self->{port2} ? $self->{port2} : 68 ),
        SuccessEvent   => '_sock_up2',
        FailureEvent   => '_sock_err2',
	($self->{address} ?
	       (BindAddress => $self->{address}) : ()),
  );

  return;
}

sub _sock_err {
  my ($kernel,$self,$operation,$errnum,$errstr,$wheel_id) = @_[KERNEL,OBJECT,ARG0..ARG3];
  delete $self->{factory};
  $self->_send_event( $self->{prefix} . 'sockbinderr', "Wheel $wheel_id generated $operation error $errnum: $errstr", 'Socket1' );
  $kernel->yield( 'shutdown' );
  return;
}

sub _sock_err2 {
  my ($kernel,$self,$operation,$errnum,$errstr,$wheel_id) = @_[KERNEL,OBJECT,ARG0..ARG3];
  delete $self->{factory};
  $self->_send_event( $self->{prefix} . 'sockbinderr', "Wheel $wheel_id generated $operation error $errnum: $errstr", 'Socket2' );
  $kernel->yield( 'shutdown' );
  return;
}


sub _sock_up {
  my ($kernel,$self,$dhcp_socket) = @_[KERNEL,OBJECT,ARG0];
  delete $self->{factory};
  $self->{socket} = $dhcp_socket;
  unless ( setsockopt( $dhcp_socket, SOL_SOCKET, SO_BROADCAST, 1 ) ) {
    $self->_send_event( $self->{prefix} . 'sockopterr', $! );
    $kernel->yield( 'shutdown' );
    return;
  }
  $kernel->select_read( $dhcp_socket, '_dhcp_read' );
  $self->_send_event( $self->{prefix} . 'socket', CORE::getsockname( $dhcp_socket ) );
  return;
}

sub _sock_up2 {
  my ($kernel,$self,$dhcp_socket) = @_[KERNEL,OBJECT,ARG0];
  delete $self->{factory2};
  $self->{socket2} = $dhcp_socket;
  unless ( setsockopt( $dhcp_socket, SOL_SOCKET, SO_BROADCAST, 1 ) ) {
    $self->_send_event( $self->{prefix} . 'sockopterr', $! );
    $kernel->yield( 'shutdown' );
    return;
  }
  $kernel->select_read( $dhcp_socket, '_dhcp_read' );
  $self->_send_event( $self->{prefix} . 'socket', CORE::getsockname( $dhcp_socket ) );
  return;
}

sub _dhcp_read {
  my ($kernel,$self,$dhcp_socket) = @_[KERNEL,OBJECT,ARG0];
  my $buffer = '';
  unless ( defined recv($dhcp_socket, $buffer, 1024, 0 ) ) {
    $self->_send_event( $self->{prefix} . 'sockrecverr', $! );
    return;
  }
  my $packet;
  eval { 
	$packet = Net::DHCP::Packet->new($buffer);
  };
  unless ( $packet ) {
    $self->_send_event( $self->{prefix} . 'sockpackerr', $@ );
    return;
  }
  $self->_send_event( $self->{prefix} . 'packet', $packet, ( sockaddr_in ( CORE::getsockname( $dhcp_socket ) ) )[0] );
  return;
}

sub register {
  my ($kernel,$self,$session,$sender) = @_[KERNEL,OBJECT,SESSION,SENDER];
  $session = $session->ID(); $sender = $sender->ID();
  $self->{sessions}->{ $sender }++;
  $kernel->refcount_increment( $sender => __PACKAGE__ ) if $self->{sessions}->{ $sender } == 1 and $sender ne $session;
  $kernel->post( $sender => $self->{prefix} . 'registered' => $self );
  undef;
}

sub unregister {
  my ($kernel,$self,$session,$sender) = @_[KERNEL,OBJECT,SESSION,SENDER];
  $session = $session->ID(); $sender = $sender->ID();
  delete $self->{sessions}->{ $sender };
  $kernel->refcount_decrement( $sender => __PACKAGE__ ) if $sender ne $session;
  $kernel->post( $sender => $self->{prefix} . 'unregistered' );
  undef;
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->alias_remove( $_ ) for $kernel->alias_list();
  $kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ ) unless $self->{alias};
  $kernel->alarm_remove_all();
  delete $self->{factory};
  my $socket = delete $self->{socket};
  my $socket2 = delete $self->{socket2};
  $kernel->select_read( $socket ) if $socket;
  $kernel->select_read( $socket2 ) if $socket2;
  $kernel->refcount_decrement( $_ => __PACKAGE__ ) for keys %{ $self->{sessions} };
  return;
}

1;


__END__
=pod

=head1 NAME

POE::Component::DHCP::Monitor - A simple POE Component for monitoring DHCP traffic.

=head1 VERSION

version 1.04

=head1 SYNOPSIS

  use strict;
  use POE;
  use POE::Component::DHCP::Monitor;
  use Net::DHCP::Packet;

  $|=1;

  POE::Session->create(
	inline_states => {
				_start		    => \&_start,
        _default      => \&_default,
				dhcp_monitor_packet => \&dhcp_monitor_packet,
	},
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    $heap->{monitor} =
	POE::Component::DHCP::Monitor->spawn(
		alias => 'monitor',       # optional
		port1  => 67,		  # default shown
		port2  => 68,		  # default shown
		address => '192.168.1.1', # default is INADDR_ANY
	);
    return;
  }

  sub dhcp_monitor_packet {
    my ($kernel,$heap,$packet) = @_[KERNEL,HEAP,ARG0];
    print STDOUT $packet->toString();
    print STDOUT "=============================================================================\n";
    return;
  }

  # This should show any unhandled events
  sub _default {
    my ($event, $args) = @_[ARG0 .. $#_];
    my @output = ( "$event: " );

    for my $arg (@$args) {
        if ( ref $arg eq 'ARRAY' ) {
            push( @output, '[' . join(', ', @$arg ) . ']' );
        }
        else {
            push ( @output, "'$arg'" );
        }
    }
    print join ' ', @output, "\n";
    return;
  }

=head1 DESCRIPTION

POE::Component::DHCP::Monitor is a simple L<POE> Component for monitoring DHCP traffic. It listens on
a specified port ( defaults to 67, which usually requires administrative privilege ). Any DHCP broadcast
traffic received will generate an event with a L<Net::DHCP::Packet> object as the first argument. You may
then query the objects methods to obtain salient information.

=head1 CONSTRUCTOR

=over

=item spawn

Starts a new POE::Component::DHCP::Monitor session. If this is called from within another POE session
then that session is automagically registered to receive events from the component. Other sessions will
have to use the 'register' event listed below.

Takes a number of arguments:

  'alias', an optional kernel alias to address the poco by;
  'address', set a particular IP address on a multi-homed box to bind to;
  'port', set a particular UDP port to listen on, default is 67;
  'port2', set a particular UDP port to listen on, default is 67;
  'options', pass a hashref of POE session options;
  'prefix', optional set the output event prefix, default is 'dhcp_monitor_';

=back

=head1 METHODS

These methods are available on the POE::Component::DHCP::Monitor object:

=over

=item session_id

Returns the POE session ID of the poco's session.

=item shutdown

Terminates the poco, unregistering all registered sessions and closes the listening socket.

=item getsockname

Returns the packed sockaddr address of this end of the first socket connection.

=item getsockname2

Returns the packed sockaddr address of this end of the second socket connection.

=back

=head1 INPUT EVENTS

The component accepts the following events:

=over

=item register

Takes no arguments. This registers your session with the component. The component will then send the
registering session a 'registered' event. The session will forthwith receive applicable events from
the component, until either the component is shutdown or the session unregisters.

=item unregister

Takes no arguments. This unregisters your session with the component. The unregistering session will
receive an 'unregistered' event.

=item shutdown

Terminates the poco, unregistering all registered sessions and closes the listening socket.

=back

=head1 OUTPUT EVENTS

The component will send the following events:

=over

=item dhcp_monitor_socket

Sent by the component to 'registered' sessions when the socket is successfully started.
ARG0 will be the packed sockaddr address of the socket.

=item dhcp_monitor_packet

Sent by the component to 'registered' sessions when a DHCP packet is received and successfully 
parsed. ARG0 will be a L<Net::DHCP::Packet>. ARG1 will be the port number this packet was received on.

=item dhcp_monitor_registered

Sent by the component to a registering session only on successful registration. ARG0 is the components
object.

=item dhcp_monitor_unregistered

Sent by the component to an unregistering session only on successful unregistration.

=item dhcp_monitor_sockbinderr

Sent by the component to 'registered' sessions when an error occurs in setting up the listening socket.
ARG0 is the error string. The component will shutdown automatically after such an error.

=item dhcp_monitor_sockopterr

Sent by the component to 'registered' sessions when an error occurs in setting the SOL_SOCKET and SO_BROADCAST options on the socket. ARG0 is the error string.
The component will shutdown automatically after such an error.

=item dhcp_monitor_sockrecverr

Sent by the component to 'registered' sessions when an error occurs in reading a packet from the socket.

=item dhcp_monitor_sockpackerr

Sent by the component to 'registered' sessions when an error occurs in parsing a received packet using L<Net::DHCP::Packet>.

=back

=head1 SEE ALSO

L<Net::DHCP::Packet>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

