package POE::Component::Server::Inet;
$POE::Component::Server::Inet::VERSION = '0.06';
#ABSTRACT: a super-server daemon implementation in POE

use strict;
use warnings;
use POE qw(Wheel::SocketFactory Wheel::Run Wheel::ReadWrite Filter::Stream);
use Net::Netmask;
use Socket;
use Carp;

sub spawn {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  my $options = delete $opts{options};
  my $self = bless \%opts, $package;
  $self->{session_id} = POE::Session->create(
	object_states => [
	    $self => { shutdown       => '_shutdown',
		       add_tcp	      => '_add_tcp',
		       del_tcp	      => '_del_tcp',
#		       add_udp	      => '_add_udp',
#		       del_udp	      => '_del_udp',
	    },
	    $self => [ qw(_start _accept_new_client _accept_failed _get_datagram _sig_child _client_input _client_flushed _client_error _wheel_out _wheel_close _wheel_error _wheel_alarm) ],
	],
	heap => $self,
	( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub session_id {
  return $_[0]->{session_id};
}

sub _conn_exists {
  my ($self,$wheel_id) = @_;
  return 0 unless $wheel_id and defined $self->{clients}->{ $wheel_id };
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
  $self->{stream_filter} = POE::Filter::Stream->new();
  return;
}

sub shutdown {
  my $self = shift;
  $poe_kernel->call( $self->{session_id}, 'shutdown' );
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->alarm_remove_all();
  $kernel->alias_remove( $_ ) for $kernel->alias_list();
  $kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ ) unless $self->{alias};
  # Shutdown TCP listeners
  delete $self->{tcp_ports};
  # Shutdown UDP listeners
  $kernel->select_read( $_->{socket} ) for values %{ $self->{udp_ports} };
  # Shutdown wheels.
  delete $self->{clients};
  delete $self->{wheels};
  return;
}

sub add_tcp {
  my $self = shift;
  $poe_kernel->call( $self->{session_id}, 'add_tcp', @_ );
}

sub del_tcp {
  my $self = shift;
  $poe_kernel->call( $self->{session_id}, 'del_tcp', @_ );
}


sub _add_tcp {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  my $args;
  if ( ref( $_[ARG0] ) eq 'HASH' ) {
    $args = { %{ $_[ARG0] } };
  } 
  else {
    $args = { @_[ARG0..$#_] };
  }
  unless ( defined $args->{port} ) { 
    warn "You must specify a 'port' parameter\n";
    return;
  }
  if ( grep { $_->{port} eq $args->{port} } values %{ $self->{tcp_ports} } ) {
    warn "There already exists a TCP port definition for '$args->{port}'\n";
    return;
  }
  unless ( $args->{program} ) {
    warn "You must specify a 'program' parameter\n";
    return;
  }
  delete $args->{programargs} unless $args->{programargs} and ref $args->{programargs} eq 'ARRAY';
  if ( $args->{allow} and !$args->{allow}->isa('Net::Netmask') ) {
    warn "'allow' parameter must be a Net::Netmask object, ignoring.\n";
    delete $args->{allow};
  }
  if ( $args->{deny} and !$args->{deny}->isa('Net::Netmask') ) {
    warn "'deny' parameter must be a Net::Netmask object, ignoring.\n";
    delete $args->{deny};
  }
  my $sockfactory = POE::Wheel::SocketFactory->new(
    ( defined $args->{bindaddress} ? ( BindAddress => $args->{bindaddress} ) : () ),
    BindPort => $args->{port},
    SuccessEvent   => '_accept_new_client',
    FailureEvent   => '_accept_failed',
    SocketDomain   => AF_INET,
    SocketType     => SOCK_STREAM,
    SocketProtocol => 'tcp',
    Reuse          => 'on',
  );
  $args->{sockfactory} = $sockfactory;
  $self->{tcp_ports}->{ $sockfactory->ID() } = $args;
  my $port = ( sockaddr_in( $sockfactory->getsockname() ) )[0];
  $args->{port} = $port;
  return $port;
}

sub _del_tcp {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  my $args;
  if ( ref( $_[ARG0] ) eq 'HASH' ) {
    $args = { %{ $_[ARG0] } };
  } 
  else {
    $args = { @_[ARG0..$#_] };
  }
  unless ( defined $args->{port} ) { 
    warn "You must specify a 'port' parameter\n";
    return;
  }
  foreach my $sockfactory_id ( keys %{ $self->{tcp_ports} } ) {
    next unless $self->{tcp_ports}->{ $sockfactory_id }->{port} eq $args->{port};
    delete $self->{tcp_ports}->{ $sockfactory_id };
    return;
  }
  return;
}


sub _accept_failed {
  my ($kernel,$self,$wheel_id) = @_[KERNEL,OBJECT,ARG3];
  warn join(' ', @_[ARG0..ARG2] ), "\n";
  delete $self->{tcp_ports}->{ $wheel_id }->{sockfactory};
  return;
}

sub _accept_new_client {
  my ($kernel,$self,$socket,$peeraddr,$peerport,$factory_id) = @_[KERNEL,OBJECT,ARG0 .. ARG3];
  $peeraddr = inet_ntoa($peeraddr);
  # Check if 'accept' or 'deny'
  my $client = POE::Wheel::ReadWrite->new (
        Handle => $socket,
        Filter => $self->{stream_filter},
        InputEvent => '_client_input',
        ErrorEvent => '_client_error',
	FlushedEvent => '_client_flushed',
  );
  my $args = $self->{tcp_ports}->{ $factory_id };
  my $wheel = POE::Wheel::Run->new(
     Program => $args->{program},
     ProgramArgs => $args->{programargs},
     StdioFilter => $self->{stream_filter},
     StderrFilter => $self->{stream_filter},
     StdoutEvent => '_wheel_out',    # Received data from the child's STDOUT.
     StderrEvent => '_wheel_out',    # Received data from the child's STDERR.
     ErrorEvent  => '_wheel_error',          # An I/O error occurred.
     CloseEvent  => '_wheel_close',  # Child closed all output handles.
     ( defined $args->{user} ? ( User => $args->{user} ) : () ),
     ( defined $args->{group} ? ( Group => $args->{group} ) : () ),
  );
  my $client_id = $client->ID();
  my $wheel_id = $wheel->ID();
  $self->{wheels}->{ $wheel_id } = { wheel => $wheel, client => $client_id, tcp => 1 };
  $self->{clients}->{ $client_id } = { wheel => $wheel_id, client => $client };
  $kernel->sig_child( $wheel->PID(), '_sig_child' );
  return;
}

sub _sig_child {
  $poe_kernel->sig_handled();
}

sub _client_input {
  my ($kernel,$self,$data,$client_id) = @_[KERNEL,OBJECT,ARG0,ARG1];
  my $wheel_id = $self->{clients}->{ $client_id }->{wheel};
  return unless $self->{wheels}->{ $wheel_id };
  $self->{wheels}->{ $wheel_id }->{wheel}->put( $data );
  return;
}

sub _client_error {
  my ($kernel,$self,$client_id) = @_[KERNEL,OBJECT,ARG3];
  my $wheel_id = $self->{clients}->{ $client_id }->{wheel};
  delete $self->{clients}->{ $client_id };
  return unless $self->{wheels}->{ $wheel_id };
  $self->{wheels}->{ $wheel_id }->{wheel}->shutdown_stdin();
  $self->{wheels}->{ $wheel_id }->{alarm} = 
	$kernel->delay_set( '_wheel_alarm', $self->{timeout} || 30, $wheel_id );
  return;
}

sub _client_flushed {
  my ($kernel,$self,$client_id) = @_[KERNEL,OBJECT,ARG0];
  $self->{clients}->{ $client_id }->{pending} = 0;
  return unless $self->{clients}->{ $client_id }->{shutdown};
  delete $self->{clients}->{ $client_id };
  return;
}

sub _wheel_out {
  my ($kernel,$self,$data,$wheel_id) = @_[KERNEL,OBJECT,ARG0,ARG1];
  if ( defined $self->{wheels}->{ $wheel_id }->{tcp} ) {
    my $client_id = $self->{wheels}->{ $wheel_id }->{client};
    return unless $self->{clients}->{ $client_id };
    $self->{clients}->{ $client_id }->{client}->put( $data );
    $self->{clients}->{ $client_id }->{pending} = 1;
  }
  return;
}

sub _wheel_alarm {
  my ($kernel,$self,$wheel_id) = @_[KERNEL,OBJECT,ARG0];
  return unless $self->{wheels}->{ $wheel_id };
  $self->{wheels}->{ $wheel_id }->{wheel}->kill(9);
  return;
}

sub _wheel_close {
  my ($kernel,$self,$wheel_id) = @_[KERNEL,OBJECT,ARG0];
  my $wdata = delete $self->{wheels}->{ $wheel_id };
  $kernel->alarm_remove( $wdata->{alarm} ) if $wdata->{alarm};
  if ( defined $wdata->{tcp} ) {
    my $client_id = $wdata->{client};
    return unless $self->{clients}->{ $client_id };
    if ( $self->{clients}->{ $client_id }->{pending} ) {
	$self->{clients}->{ $client_id }->{shutdown} = 1;
	return;
    }
    delete $self->{clients}->{ $client_id };
  }
  return;
}

sub _wheel_error {
  my ($operation, $errnum, $errstr, $wheel_id) = @_[ARG0..ARG3];
  return if $operation eq "read" and !$errnum;
  $errstr = "remote end closed" if $operation eq "read" and !$errnum;
  warn "Wheel $wheel_id generated $operation error $errnum: $errstr\n";
  return;
}

sub _get_datagram {
}

qq[Inet in'it];

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Server::Inet - a super-server daemon implementation in POE

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  use strict;
  use warnings;
  use POE qw(Component::Server::Inet);

  $|=1;

  my $inetd = POE::Component::Server::Inet->spawn( options => { trace => 0 } );

  my $echo = $inetd->add_tcp( port => 0, program => \&_echo );

  print "Started echo server on port: $echo\n";

  my $fake = $inetd->add_tcp( port => 0, program => \&_fake );

  print "Started a 'fake' server on $fake\n";

  my $fake2 = $inetd->add_tcp( port => 0, program => \&_fake2 );

  print "Started another 'fake' server on $fake2\n";

  $poe_kernel->run();
  exit 0;

  sub _echo {
    use FileHandle;
    autoflush STDOUT 1;
    while(<STDIN>) {
      print STDOUT $_;
    }
    return;
  }

  sub _fake {
    return;
  }

  sub _fake2 {
    sleep 10000000000;
    return;
  }

=head1 DESCRIPTION

POE::Component::Server::Inet is an Inetd ( L<http://en.wikipedia.org/wiki/Inetd> ) C<super-server>
implementation in L<POE>. It currently only supports TCP based connections.

You may either specify programs to run or use coderefs.

The component uses L<POE::Wheel::Run> to do its magic.

=begin comment

sub add_udp {
  my $self = shift;
  $poe_kernel->call( $self->{session_id}, 'add_udp', @_ );
}

sub del_udp {
  my $self = shift;
  $poe_kernel->call( $self->{session_id}, 'del_udp', @_ );
}

=end comment

=begin comment

sub _add_udp {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  my $args;
  if ( ref( $_[ARG0] ) eq 'HASH' ) {
    $args = { %{ $_[ARG0] } };
  } 
  else {
    $args = { @_[ARG0..$#_] };
  }
  unless ( defined $args->{port} ) { 
    warn "You must specify a 'port' parameter\n";
    return;
  }
  unless ( $args->{program} ) {
    warn "You must specify a 'program' parameter\n";
    return;
  }
  if ( defined $self->{udp_ports}->{ $args->{port} } ) {
    warn "There already exists a UDP port definition for '$args->{port}'\n";
    return;
  }
  if ( $args->{allow} and !$args->{allow}->isa('Net::Netmask') ) {
    warn "'allow' parameter must be a Net::Netmask object, ignoring.\n";
    delete $args->{allow};
  }
  if ( $args->{deny} and !$args->{deny}->isa('Net::Netmask') ) {
    warn "'deny' parameter must be a Net::Netmask object, ignoring.\n";
    delete $args->{deny};
  }
  my $proto = getprotobyname('udp');
  my $paddr = sockaddr_in( $args->{port}, $args->{bindaddress} || INADDR_ANY );
  socket( my $socket, PF_INET, SOCK_DGRAM, $proto) || carp "Couldn\'t create UDP socket\n";
  bind( $socket, $paddr) || carp "Couldn\'t bind to UDP socket\n";
  $args->{socket} = $socket;
  $self->{udp_ports}->{ $args->{port} } = $args;
  $kernel->select_read( $socket, '_get_datagram', $args->{port} );
  return;
}

sub _del_udp {
}

=end comment

=head1 CONSTRUCTOR

=over

=item spawn

Starts a POE::Component::Server::Inet session and returns an object. Takes a number of optional arguments:

  'alias', an alias to address the component by;
  'options', a hashref of POE::Session options;
  'timeout', a number in seconds to wait before forcefully terminating forked processes, default 30;

=back

=head1 METHODS

=over

=item session_id

Takes no arguments. Returns the POE Session ID of the component.

=item add_tcp

Adds a TCP listener to the component. Takes a number of parameters:

  'port', the port to listen on, mandatory ( can be set to 0 if required );
  'program', a program or coderef to execute for each connection, mandatory;
  'programargs', an arrayref of parameters for the program being run;
  'allow', a Net::Netmask object of hosts to allow to connect;
  'deny', a Net::Ntemask object of hosts to deny connections from;
  'user', the UID of a user to switch to;
  'group', the GID of a group to switch to;

Options C<program>, C<programargs>, C<user> and C<group> are passed directly to L<POE::Wheel::Run>'s
constructor, please check that documentation for extra information.

The method call returns the port that was assigned.

=item del_tcp

Removes a TCP listener. Takes one mandatory parameter:

  'port', the port to remove;

Any pending connections are dealt with.

=item shutdown

Terminates the component. All connections and wheels are closed.

=back

=head1 SEE ALSO

L<POE>

L<http://en.wikipedia.org/wiki/Inetd>

L<POE::Wheel::Run>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
