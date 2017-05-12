# $Id: Echo.pm,v 1.3 2005/01/27 08:37:22 chris Exp $
#
# POE::Component::Server::Echo, by Chris 'BinGOs' Williams <chris@bingosnet.co.uk>
#
# This module may be used, modified, and distributed under the same
# terms as Perl itself. Please see the license that came with your Perl
# distribution for details.
#

package POE::Component::Server::Echo;
$POE::Component::Server::Echo::VERSION = '1.66';
#ABSTRACT: A POE component that implements an RFC 862 Echo server.

use strict;
use warnings;
use POE qw( Wheel::SocketFactory Wheel::ReadWrite Driver::SysRW
            Filter::Line );
use Carp;
use Socket;
use IO::Socket::INET;

use constant DATAGRAM_MAXLEN => 1024;
use constant DEFAULT_PORT => 7;

sub spawn {
  my $package = shift;
  croak "$package requires an even number of parameters" if @_ & 1;

  my %parms = @_;

  $parms{'Alias'} = 'Echo-Server' unless defined $parms{'Alias'} and $parms{'Alias'};
  $parms{'tcp'} = 1 unless defined $parms{'tcp'} and $parms{'tcp'} == 0;
  $parms{'udp'} = 1 unless defined $parms{'udp'} and $parms{'udp'} == 0;

  my $self = bless( { }, $package );

  $self->{CONFIG} = \%parms;

  POE::Session->create(
	object_states => [
		$self => { _start => '_server_start',
			   _stop  => '_server_stop',
			   shutdown => '_server_close' },
		$self => [ qw(_accept_new_client _accept_failed _client_input _client_error _get_datagram) ],
			  ],
	( ref $parms{'options'} eq 'HASH' ? ( options => $parms{'options'} ) : () ),
  );

  return $self;
}

sub _server_start {
  my ($kernel,$self) = @_[KERNEL,OBJECT];

  $kernel->alias_set( $self->{CONFIG}->{Alias} );

  if ( $self->{CONFIG}->{tcp} ) {
    $self->{Listener} = POE::Wheel::SocketFactory->new(
      ( defined ( $self->{CONFIG}->{BindAddress} ) ? ( BindAddress => $self->{CONFIG}->{BindAddress} ) : () ),
      ( defined ( $self->{CONFIG}->{BindPort} ) ? ( BindPort => $self->{CONFIG}->{BindPort} ) : ( BindPort => DEFAULT_PORT ) ),
      SuccessEvent   => '_accept_new_client',
      FailureEvent   => '_accept_failed',
      SocketDomain   => AF_INET,             # Sets the socket() domain
      SocketType     => SOCK_STREAM,         # Sets the socket() type
      SocketProtocol => 'tcp',               # Sets the socket() protocol
      Reuse          => 'on',                # Lets the port be reused
    );
  }
  if ( $self->{CONFIG}->{udp} ) {
    my $proto = getprotobyname('udp');
    my $port = defined ( $self->{CONFIG}->{BindPort} ) ? $self->{CONFIG}->{BindPort} : DEFAULT_PORT;
    my $paddr = sockaddr_in($port, INADDR_ANY);
    socket( my $socket, PF_INET, SOCK_DGRAM, $proto)   || die "socket: $!";
    bind( $socket, $paddr)                          || die "bind: $!";
    $self->{udp_socket} = $socket;
    $kernel->select_read( $self->{udp_socket}, "_get_datagram" );
  }
  undef;
}

sub _server_stop {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  undef;
}

sub _server_close {
  my ($kernel,$self) = @_[KERNEL,OBJECT];

  delete $self->{Listener};
  delete $self->{Clients};
  $kernel->select( $self->{udp_socket} );
  delete $self->{udp_socket};
  $kernel->alias_remove( $self->{CONFIG}->{Alias} );
  undef;
}

sub _accept_new_client {
  my ($kernel,$self,$socket,$peeraddr,$peerport) = @_[KERNEL,OBJECT,ARG0 .. ARG2];
  $peeraddr = inet_ntoa($peeraddr);

  my $wheel = POE::Wheel::ReadWrite->new (
        Handle => $socket,
        Filter => POE::Filter::Line->new(),
        InputEvent => '_client_input',
        ErrorEvent => '_client_error',
  );

  my $wheel_id = $wheel->ID();
  $self->{Clients}->{ $wheel_id }->{Wheel} = $wheel;
  $self->{Clients}->{ $wheel_id }->{peeraddr} = $peeraddr;
  $self->{Clients}->{ $wheel_id }->{peerport} = $peerport;
  undef;
}

sub _accept_failed {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->yield( 'shutdown' );
  undef;
}

sub _client_input {
  my ($kernel,$self,$input,$wheel_id) = @_[KERNEL,OBJECT,ARG0,ARG1];

  if ( defined ( $self->{Clients}->{ $wheel_id } ) and defined ( $self->{Clients}->{ $wheel_id }->{Wheel} ) ) {
	$self->{Clients}->{ $wheel_id }->{Wheel}->put($input);
  }
  undef;
}

sub _client_error {
  my ($self,$wheel_id) = @_[OBJECT,ARG3];
  delete $self->{Clients}->{ $wheel_id };
  undef;
}

sub _get_datagram {
  my ( $kernel, $socket ) = @_[ KERNEL, ARG0 ];

  my $remote_address = recv( $socket, my $message = "", DATAGRAM_MAXLEN, 0 );
    return unless defined $remote_address;

  send( $socket, $message, 0, $remote_address ) == length($message)
      or warn "Trouble sending response: $!";
  undef;
}

sub sockname_tcp {
  my $self = shift;
  my $name;
  $name =  $self->{Listener}->getsockname() if $self->{CONFIG}->{tcp};
  return unless $name;
  return sockaddr_in($name);
}

sub sockname_udp {
  my $self = shift;
  return unless $self->{CONFIG}->{udp} and $self->{udp_socket};
  return sockaddr_in( getsockname $self->{udp_socket} );
}

qq[ECHO! ECHO...ECHO...ECHO...ECHO...ECHO...ECHO...ECHo...ECho...Echo...echo];

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Server::Echo - A POE component that implements an RFC 862 Echo server.

=head1 VERSION

version 1.66

=head1 SYNOPSIS

  use POE::Component::Server::Echo;

  my $self = POE::Component::Server::Echo->spawn( 
	Alias => 'Echo-Server',
	BindAddress => '127.0.0.1',
	BindPort => 7777,
	options => { trace => 1 },
  );

=head1 DESCRIPTION

POE::Component::Server::Echo implements a RFC 862 L<http://www.faqs.org/rfcs/rfc862.html> TCP/UDP echo server, using
L<POE>. The component encapsulates a class which may be used to implement further RFC protocols.

=head1 CONSTRUCTOR

=over

=item C<spawn>

Takes a number of optional values:

  "Alias", the kernel alias that this component is to be blessed with; 
  "BindAddress", the address on the local host to bind to, 
	defaults to L<POE::Wheel::SocketFactory|POE::Wheel::SocketFactory> default; 
  "BindPort", the local port that we wish to listen on for requests, 
        defaults to 7 as per RFC, this will require "root" privs on UN*X; 
  "options", should be a hashref, containing the options for the component's session, 
        see POE::Session for more details on what this should contain.

=back

=head1 METHODS

=over

=item C<sockname_tcp>

Takes no arguments. Returns a list consisting of the socket port and address of the TCP listening socket as returned by Socket's sockaddr_in function.

=item C<sockname_udp>

Takes no arguments. Returns a list consisting of the socket port and address of the UDP listening socket as returned by Socket's sockaddr_in function.

=back

=head1 INPUT EVENTS

=over

=item C<shutdown>

Takes no arguments. Shuts down the component gracefully, terminating all listeners and disconnecting all connected clients.

=back

=head1 BUGS

Report any bugs through L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<POE>

L<POE::Session>

L<POE::Wheel::SocketFactory>

L<http://www.faqs.org/rfcs/rfc862.html>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
