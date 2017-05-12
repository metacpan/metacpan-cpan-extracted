package POE::Component::Server::Ident;
$POE::Component::Server::Ident::VERSION = '1.18';
#ABSTRACT: A POE component that provides non-blocking ident services to your sessions.

use 5.006;
use strict;
use warnings;
use POE qw( Wheel::SocketFactory Wheel::ReadWrite Driver::SysRW
            Filter::Line );
use Carp;
use Socket;

sub spawn {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;

  $opts{bindport} = 113 unless defined $opts{bindport};
  $opts{multiple} = 0 unless $opts{multiple};
  $opts{timeout} = 60 unless $opts{timeout};
  $opts{random} = 0 unless $opts{random};

  my $self = bless \%opts, $package;

  $self->{session_id} = POE::Session->create (
	object_states => [
		$self => { _start     => '_server_start',
			   'shutdown' => '_server_close',
			   map { ( $_ => '_' . $_ ) } qw(accept_new_client accept_failed),
			 },
		$self => [ qw(register unregister) ],
	],
  )->ID();
  return $self;
}

sub session_id {
  return $_[0]->{session_id};
}

sub getsockname {
  my $self = shift;
  return $self->{listener}->getsockname();
}

sub _server_start {
  my ($kernel,$self,$session) = @_[KERNEL,OBJECT,SESSION];
  $self->{session_id} = $session->ID();

  $kernel->alias_set( $self->{alias} ) if $self->{alias};
  $kernel->refcount_increment( $self->{session_id}, __PACKAGE__ ) unless $self->{alias};

  $self->{listener} = POE::Wheel::SocketFactory->new (
			BindPort => $self->{bindport},
			( $self->{bindaddr} ? (BindAddr => $self->{bindaddr}) : () ),
			Reuse => 'on',
			SuccessEvent => 'accept_new_client',
			FailureEvent => 'accept_failed',
  );
  undef;
}

sub _server_close {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->alias_remove( $_ ) for $kernel->alias_list();
  $kernel->refcount_decrement( $self->{session_id}, __PACKAGE__ ) unless $self->{alias};
  $kernel->post( $_, 'client_timeout' ) for %{ $self->{clients} };
  delete $self->{listener};
  $kernel->refcount_decrement( $_, __PACKAGE__ ) for keys %{ $self->{sessions} };
  undef;
}

sub _accept_new_client {
  my ($kernel,$self,$socket,$peeraddr,$peerport) = @_[KERNEL,OBJECT,ARG0 .. ARG2];
  $peeraddr = inet_ntoa($peeraddr);

  POE::Session->create (
	object_states => [
		$self => { _start => '_client_start',
			   _stop  => '_client_stop',
			   map { ( $_ => '_' . $_ ) } qw(client_input client_error client_done client_timeout client_default),
			 },
		$self => [ qw(ident_server_reply ident_server_error) ],
	],
	args => [ $socket, $peeraddr, $peerport ],
  );
  undef;
}

sub _accept_failed {
  my ($kernel,$self,$function,$error) = @_[KERNEL,OBJECT,ARG0,ARG2];
  my $package = ref $self;

  $kernel->call ( $self->{session_id}, 'shutdown' );

  warn "$package: call to $function() failed: $error";
  undef;
}

sub register {
  my ($kernel,$self,$sender,$session) = @_[KERNEL,OBJECT,SENDER,SESSION];
  $sender = $sender->ID();
  $session = $session->ID();

  $self->{sessions}->{ $sender }++;
  $kernel->refcount_increment( $sender => __PACKAGE__ )
       if $self->{sessions}->{ $sender } == 1 and $sender ne $session;
  undef;
}


sub unregister {
  my ($kernel,$self,$sender,$session) = @_[KERNEL,OBJECT,SENDER,SESSION];
  my $thing = delete $self->{sessions}->{ $sender };
  $kernel->refcount_decrement( $sender => __PACKAGE__ )
	if $thing and $sender ne $session;
  return;
}

sub _client_start {
  my ($kernel,$session,$self,$socket,$peeraddr,$peerport) = @_[KERNEL,SESSION,OBJECT,ARG0,ARG1,ARG2];
  my $session_id = $session->ID();

  $self->{clients}->{ $session_id }->{PeerAddr} = $peeraddr;
  $self->{clients}->{ $session_id }->{PeerPort} = $peerport;

  $self->{clients}->{ $session_id }->{readwrite} =
  POE::Wheel::ReadWrite->new(
	Handle => $socket,
	Filter => POE::Filter::Line->new( Literal => "\x0D\x0A" ),
	InputEvent => 'client_input',
	ErrorEvent => 'client_error',
	( $self->{'multiple'} ? () : ( FlushedEvent => 'client_timeout' ) ),
  );

  # Set a delay to close the connection if we are idle for 60 seconds.
  $kernel->delay ( 'client_timeout' => $self->{'timeout'} );
  undef;
}

sub _client_stop {
  my ($kernel,$self,$session) = @_[KERNEL,OBJECT,SESSION];

  $kernel->delay ( 'client_timeout' => undef );
  delete $self->{clients}->{ $session->ID };
  undef;
}

sub _client_input {
  my ($kernel,$self,$session,$input) = @_[KERNEL,OBJECT,SESSION,ARG0];
  my $session_id = $session->ID();

  # Parse what is passed. We want <number>,<number> or nothing.

  if ( $input =~ /^\s*([0-9]+)\s*,\s*([0-9]+)\s*$/ and _valid_ports($1,$2) ) {
    my $port1 = $1; my $port2 = $2;
    $self->{clients}->{ $session_id }->{'Port1'} = $port1;
    $self->{clients}->{ $session_id }->{'Port2'} = $port2;
    # Okay got a sort of valid query. Send it to all interested sessions.
    $kernel->call( $_ => 'identd_request' => $self->{clients}->{ $session_id }->{PeerAddr} => $port1 => $port2 ) for keys %{ $self->{sessions} };
    $kernel->delay ( 'client_default' => 10 );
  } else {
    # Client sent us rubbish.
    $self->{clients}->{ $session_id }->{readwrite}->put("0 , 0 : ERROR : INVALID-PORT");
  }
  $kernel->delay ( 'client_timeout' => $self->{'timeout'} ) if $self->{'multiple'};
  undef;
}

sub _client_done {
  my ($kernel,$self,$session) = @_[KERNEL,OBJECT,SESSION];
  $kernel->delay ( 'client_timeout' => undef );
  delete $self->{clients}->{ $session->ID };
  undef;
}

sub _client_error {
  my ($kernel,$self,$session) = @_[KERNEL,OBJECT,SESSION];
  $kernel->delay ( 'client_timeout' => undef );
  delete $self->{clients}->{ $session->ID }->{readwrite};
  undef;
}

sub _client_timeout {
  my ($kernel,$self,$session) = @_[KERNEL,OBJECT,SESSION];
  $kernel->delay ( 'client_timeout' => undef );
  $kernel->delay ( 'client_default' => undef );
  delete $self->{clients}->{ $session->ID }->{readwrite};
  undef;
}

sub _client_default {
  my ($kernel,$self,$session) = @_[KERNEL,OBJECT,SESSION];
  my $session_id = $session->ID();

  my $reply = $self->{clients}->{ $session_id }->{'Port1'} . " , " . $self->{clients}->{ $session_id }->{'Port2'};
  SWITCH: {
    if ( $self->{'default'} ) {
	$reply .= " : USERID : UNIX : " . $self->{'default'};
	last SWITCH;
    }
    if ( $self->{'random'} ) {
    	srand( $session_id * $$ );
    	my @numbers;
    	push @numbers, int rand (26) for 1 .. 8;
    	my $user_id = join '', map { chr($_+97) } @numbers;
	$reply .= " : USERID : UNIX : $user_id";
	last SWITCH;
    }
    $reply .= " : ERROR : HIDDEN-USER";
  }
  $self->{clients}->{ $session_id }->{readwrite}->put($reply) if defined $self->{clients}->{ $session_id }->{readwrite};
  $kernel->delay ( 'client_timeout' => $self->{'timeout'} ) if $self->{'multiple'};
  undef;
}

sub ident_server_reply {
  my ($kernel,$self,$session) = @_[KERNEL,OBJECT,SESSION];
  my $session_id = $session->ID();

  my ($opsys,$userid) = @_[ARG0 .. ARG1];

  $opsys = "UNIX" unless defined ( $opsys );

  my $reply = $self->{clients}->{ $session_id }->{'Port1'} . " , " . $self->{clients}->{ $session_id }->{'Port2'} . " : USERID : " . $opsys . " : " . $userid;

  $self->{clients}->{ $session_id }->{readwrite}->put($reply) if $self->{clients}->{ $session_id }->{readwrite};
  $kernel->delay ( 'client_timeout' => $self->{'timeout'} ) if $self->{'multiple'};
  $kernel->delay ( 'client_default' => undef );
  undef;
}

sub ident_server_error {
  my ($kernel,$self,$session,$error_type) = @_[KERNEL,OBJECT,SESSION,ARG0];
  my $session_id = $session->ID();
  $error_type = uc $error_type;

  unless ( grep {$_ eq $error_type} qw(INVALID-PORT NO-USER HIDDEN-USER UNKNOWN-ERROR) ) {
	$error_type = 'UNKNOWN-ERROR';
  }

  my $reply = $self->{clients}->{ $session_id }->{'Port1'} . " , " . $self->{clients}->{ $session_id }->{'Port2'} . " : ERROR : " . $error_type;

  $self->{clients}->{ $session_id }->{readwrite}->put($reply) if $self->{clients}->{ $session_id }->{readwrite};
  $kernel->delay ( 'client_timeout' => $self->{'timeout'} ) if $self->{'multiple'};
  $kernel->delay ( 'client_default' => undef );
  undef;
}

sub _valid_ports {
  my ($port1,$port2) = @_;

  return 1 if ( defined ( $port1 ) and defined ( $port2 ) ) and ( $port1 >= 1 and $port1 <= 65535 ) and ( $port2 >= 1 and $port2 <= 65535 );
  return 0;
}

qq{Papers, please};

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Server::Ident - A POE component that provides non-blocking ident services to your sessions.

=head1 VERSION

version 1.18

=head1 SYNOPSIS

   use strict;
   use warnings;
   use POE qw(Component::Server::Ident);

   POE::Component::Server::Ident->spawn ( Alias => 'Ident-Server' );

   POE::Session->create (
	package_states => [
		'main' => [qw(_start identd_request)],
	],
   );

   $poe_kernel->run();
   exit 0;

   sub _start {
      $poe_kernel->post( 'Ident-Server' => 'register' );
      undef;
   }


   sub identd_request {
      my ($kernel,$sender,$peeraddr,$port1,$port2) = @_[KERNEL,SENDER,ARG0,ARG1,ARG2];
      my ($val1,$val2);
      $val1 = $val2 = int(rand(99999));
      $val1 =~ tr/0-9/A-Z/;
      $kernel->call ( $sender => ident_server_reply => 'OTHER' => "$val1$val2" );
      undef;
   }

=head1 DESCRIPTION

POE::Component::Server::Ident is a L<POE> component that provides
a non-blocking Identd for other components and POE sessions.

Spawn the component, give it an an optional lias and it will sit there waiting for Ident clients to connect.
Register with the component to receive ident events. The component will listen for client connections.
A valid ident request made by a client will result in an 'identd_server' event being sent to your
session. You may send back 'ident_server_reply' or 'ident_server_error' depending on what the client
sent.

The component will automatically respond to the client requests with 'ERROR : HIDDEN-USER' if your
sessions do not send a respond within a 10 second timeout period. This can be adjusted with 'Random'
and 'Default' options to spawn().

=head1 CONSTRUCTOR

=over

=item C<spawn>

Takes a number of arguments:

  'Alias',    a kernel alias to address the component with;
  'BindAddr', the IP address that the component should bind to,
	      defaults to INADDR_ANY;
  'BindPort', the port that the component will bind to, default is 113;
  'Multiple', specify whether the component should allow multiple ident queries
              from clients by setting this to 1, default is 0 which terminates
              client connections after a response has been sent;
  'TimeOut',  this is the idle timeout on client connections, default
              is 60 seconds, accepts values between 60 and 180 seconds.
  'Default',  provide a default userid to return if your sessions don't provide a
              response.
  'Random',   the component will generate a random userid string if your sessions
	      don't provide a response.

=back

=head1 METHODS

=over

=item C<session_id>

Retrieve the component's POE session ID.

=item C<getsockname>

Access to the L<POE::Wheel::SocketFactory> method of the underlying listening socket.

=back

=head1 INPUT

The component accepts the following events:

=over

=item C<register>

Takes no arguments. This registers your session with the component. The component will then send you
'identd_request' events when clients make valid ident requests. See below.

=item C<unregister>

Takes no arguments. This unregisters your session with the component.

=item C<ident_server_reply>

Takes two arguments, the first is the 'opsys' field of the ident response, the second is the 'userid'.

=item C<ident_server_error>

Takes one argument, the error to return to the client.

=item C<shutdown>

Terminates the component. The listener is closed and all current client connections are disconnected.

=back

=head1 OUTPUT

The component will send the following events:

=over

=item C<identd_request>

Sent by the component to 'registered' sessions when a client makes a valid ident request. ARG0 is
the IP address of the client, ARG1 and ARG2 are the ports as specified in the ident request. You
can use the 'ident_server_reply' and 'ident_server_error' to respond to the client appropriately. Please
note, that you send these responses to $_[SENDER] not the kernel alias of the component.

=back

=head1 SEE ALSO

L<POE>

RFC 1413 L<http://www.faqs.org/rfcs/rfc1413.html>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
