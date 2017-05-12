# Author: Chris "BinGOs" Williams
#
# This module may be used, modified, and distributed under the same
# terms as Perl itself. Please see the license that came with your Perl
# distribution for details.
#

package POE::Component::Client::Ident::Agent;

use strict;
use warnings;
use POE qw( Wheel::SocketFactory Wheel::ReadWrite Driver::SysRW
            Filter::Line Filter::Stream Filter::Ident);
use Carp;
use Socket;
use vars qw($VERSION);

$VERSION = '1.16';

sub spawn {
    my $package = shift;

    my ($peeraddr,$peerport,$sockaddr,$sockport,$identport,$buggyidentd,$timeout,$reference) = _parse_arguments(@_);
 
    unless ( $peeraddr and $peerport and $sockaddr and $sockport ) {
        croak "Not enough arguments supplied to $package->spawn";
    }

    my $self = $package->_new($peeraddr,$peerport,$sockaddr,$sockport,$identport,$buggyidentd,$timeout,$reference);

    $self->{session_id} = POE::Session->create(
        object_states => [
	    $self => { shutdown => '_shutdown', },
            $self => [qw(_start _sock_up _sock_down _sock_failed _parse_line _time_out)],
        ],
    )->ID();

    return $self;
}

sub _new {
    my ( $package, $peeraddr, $peerport, $sockaddr, $sockport, $identport, $buggyidentd, $timeout, $reference) = @_;
    return bless { event_prefix => 'ident_agent_', peeraddr => $peeraddr, peerport => $peerport, sockaddr => $sockaddr, sockport => $sockport, identport => $identport, buggyidentd => $buggyidentd, timeout => $timeout, reference => $reference }, $package;
}

sub session_id {
  return $_[0]->{session_id};
}

sub _start {
    my ( $kernel, $self, $session, $sender ) = @_[ KERNEL, OBJECT, SESSION, SENDER ];

    $self->{sender} = $sender->ID();
    $self->{session_id} = $session->ID();
    $self->{ident_filter} = POE::Filter::Ident->new();
    $kernel->delay( '_time_out' => $self->{timeout} );
    $self->{socketfactory} = POE::Wheel::SocketFactory->new(
                                        SocketDomain => AF_INET,
                                        SocketType => SOCK_STREAM,
                                        SocketProtocol => 'tcp',
                                        RemoteAddress => $self->{'peeraddr'},
                                        RemotePort => ( $self->{'identport'} ? ( $self->{'identport'} ) : ( 113 ) ),
                                        SuccessEvent => '_sock_up',
                                        FailureEvent => '_sock_failed',
                                        ( $self->{sockaddr} ? (BindAddress => $self->{sockaddr}) : () ),
    );
    $self->{query_string} = $self->{peerport} . ", " . $self->{sockport};
    $self->{query} = { PeerAddr => $self->{peeraddr}, PeerPort => $self->{peerport}, SockAddr => $self->{sockaddr}, SockPort => $self->{sockport}, Reference => $self->{reference} };
    undef;
}

sub _sock_up {
  my ($kernel,$self,$socket) = @_[KERNEL,OBJECT,ARG0];
  my $filter;

  delete $self->{socketfactory};

  if ( $self->{buggyidentd} ) {
	$filter = POE::Filter::Line->new();
  } else {
	$filter = POE::Filter::Line->new( Literal => "\x0D\x0A" );
  }

  $self->{socket} = new POE::Wheel::ReadWrite
  (
        Handle => $socket,
        Driver => POE::Driver::SysRW->new(),
        Filter => $filter,
        InputEvent => '_parse_line',
        ErrorEvent => '_sock_down',
  );

  $kernel->post( $self->{sender}, $self->{event_prefix} . 'error', $self->{query}, "UKNOWN-ERROR" ) unless $self->{socket};
  $self->{socket}->put($self->{query_string}) if $self->{socket};
  $kernel->delay( '_time_out' => $self->{timeout} );
  undef;
}

sub _sock_down {
  my ($kernel,$self) = @_[KERNEL,OBJECT];

  $kernel->post( $self->{sender}, $self->{event_prefix} . 'error', $self->{query}, "UKNOWN-ERROR" ) unless $self->{had_a_response};
  delete $self->{socket};
  $kernel->delay( '_time_out' => undef );
  undef;
}


sub _sock_failed {
  my ($kernel, $self) = @_[KERNEL,OBJECT];

  $kernel->post( $self->{sender}, $self->{event_prefix} . 'error', $self->{query}, "UKNOWN-ERROR" );
  $kernel->delay( '_time_out' => undef );
  delete $self->{socketfactory};
  undef;
}

sub _time_out {
  my ($kernel,$self) = @_[KERNEL,OBJECT];

  $kernel->post( $self->{sender}, $self->{event_prefix} . 'error', $self->{query}, "UKNOWN-ERROR" );
  delete $self->{socketfactory};
  delete $self->{socket};
  undef;
}

sub _parse_line {
  my ($kernel,$self,$line) = @_[KERNEL,OBJECT,ARG0];
  my @cooked;

  @cooked = @{$self->{ident_filter}->get( [$line] )};

  foreach my $ev (@cooked) {
    if ( $ev->{name} eq 'barf' ) {
	# Filter choaked for whatever reason
        $kernel->post( $self->{sender}, $self->{event_prefix} . 'error', $self->{query}, "UKNOWN-ERROR" );
    } else {
      $ev->{name} = $self->{event_prefix} . $ev->{name};
      my ($port1, $port2, @args) = @{$ev->{args}};
      if ( $self->_port_pair_matches( $port1, $port2 ) ) {
        $kernel->post( $self->{sender}, $ev->{name}, $self->{query}, @args );
      } else {
        $kernel->post( $self->{sender}, $self->{event_prefix} . 'error', $self->{query}, "UKNOWN-ERROR" );
      }
    }
  }
  $kernel->delay( '_time_out' => undef );
  $self->{had_a_response} = 1;
  delete $self->{socket};
  undef;
}

sub shutdown {
  my $self = shift;
  $poe_kernel->call( $self->session_id() => 'shutdown' => @_ );
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $self->{had_a_response} = 1;
  delete $self->{socket};
  $kernel->delay( '_time_out' => undef );
  undef;
}

sub _port_pair_matches {
  my ($self) = shift;
  my ($port1,$port2) = @_;
  return 1 if $port1 == $self->{peerport} and $port2 == $self->{sockport};
  return 0;
}

sub _parse_arguments {
  my ( %hash ) = @_;
  my @returns;

  # If we get a socket it takes precedence over any other arguments
  SWITCH: {
	if ( defined ( $hash{'Reference'} ) ) {
	  $returns[7] = $hash{'Reference'};
	}
        if ( defined ( $hash{'IdentPort'} ) ) {
	  $returns[4] = $hash{'IdentPort'};
        }
	if ( defined ( $hash{'BuggyIdentd'} ) and $hash{'BuggyIdentd'} == 1 ) {
	  $returns[5] = $hash{'BuggyIdentd'};
	}
	if ( defined ( $hash{'TimeOut'} ) and ( $hash{'TimeOut'} > 5 or $hash{'TimeOut'} < 30 ) ) {
	  $returns[6] = $hash{'TimeOut'};
        }
	$returns[6] = 30 unless ( defined ( $returns[6] ) );
	if ( defined ( $hash{'Socket'} ) ) {
	  $returns[0] = inet_ntoa( (unpack_sockaddr_in( getpeername $hash{'Socket'} ))[1] );
    	  $returns[1] = (unpack_sockaddr_in( getpeername $hash{'Socket'} ))[0];
	  $returns[2] = inet_ntoa( (unpack_sockaddr_in( getsockname $hash{'Socket'} ))[1] );
          $returns[3] = (unpack_sockaddr_in( getsockname $hash{'Socket'} ))[0];
	  last SWITCH;
	}
	if ( defined ( $hash{'PeerAddr'} ) and defined ( $hash{'PeerPort'} ) and defined ( $hash{'SockAddr'} ) and defined ( $hash{'SockAddr'} ) ) {
	  $returns[0] = $hash{'PeerAddr'};
    	  $returns[1] = $hash{'PeerPort'};
	  $returns[2] = $hash{'SockAddr'};
          $returns[3] = $hash{'SockPort'};
	  last SWITCH;
        }
  }
  return @returns;
}

'Who are you?';

__END__

=head1 NAME

POE::Component::Client::Ident::Agent - A component to provide a one-shot non-blocking Ident query.

=head1 SYNOPSIS

  use POE::Component::Client::Ident::Agent;

  my $poco = POE::Component::Client::Ident::Agent->spawn( 
	PeerAddr => "192.168.1.12", # Originating IP Address
	PeerPort => 12345,	    # Originating port
	SockAddr => "192.168.2.24", # Local IP address
	SockPort => 69,		    # Local Port
	Socket   => $socket_handle, # Or pass in a socket handle
	IdentPort => 113,	    # Port to send queries to on originator
				    # Default shown
	BuggyIdentd => 0,	    # Dealing with an Identd that isn't
				    # RFC compatable. Default is 0.
	TimeOut => 30,		    # Adjust the timeout period.
	Reference => $scalar	    # Give the component a reference
  );

  sub _child {
   my ($action,$child,$reference) = @_[ARG0,ARG1,ARG2];

   if ( $action eq 'create' ) {
     # Stuff
   }
  }

  sub ident_agent_reply {
  }

  sub ident_agent_error {
  }

=head1 DESCRIPTION

POE::Component::Client::Ident::Agent is a POE component that provides a single "one shot" look up of a username
on the remote side of a TCP connection to other components and sessions, using the ident (auth/tap) protocol.
The Ident protocol is described in RFC 1413 L<http://www.faqs.org/rfcs/rfc1413.html>.

The component implements a single ident request. Your session spawns the component, passing the relevant arguments and at 
some future point will receive either a 'ident_agent_reply' or 'ident_agent_error', depending on the outcome of the query.

If you are looking for a robust method of managing Ident::Agent sessions then please consult the documentation for 
L<POE::Component::Client::Ident>, which takes care of Agent management for you.

=head1 CONSTRUCTOR 

=over

=item C<spawn>

Takes either the arguments: 

  "PeerAddr", the remote IP address where a TCP connection has originated; 
  "PeerPort", the port where the TCP has originated from;
  "SockAddr", the address of our end of the connection; 
  "SockPort", the port of our end of the connection;

OR: 

  "Socket", the socket handle of the connection, the component will work out all the 
  details for you. If Socket is defined, it will override the settings of the other arguments, 
  except for:

  "IdentPort", which is the port on the remote host where we send our ident queries.
  This is optional, defaults to 113.

You may also specify BuggyIdentd to 1, to support Identd that doesn't terminate lines as per the RFC.

You may also specify TimeOut between 5 and 30, to have a shorter timeout in seconds on waiting for a response from the Identd. Default is 30 seconds.

Optionally, you can specify Reference, which is anything that'll fit in a scalar. This will get passed back as part of the response. See below.

Returns an POE::Component::Client::Ident::Agent object, which has the following methods.

=back

=head1 METHODS

=over

=item C<session_id>

Returns the POE session ID of the component.

=item C<shutdown>

Terminates the component.

=back

=head1 OUTPUT

All the events returned by the component have a hashref as ARG0. This hashref contains the arguments that were passed to
the component. If a socket handle was passed, the hashref will contain the appropriate PeerAddr, PeerPort, SockAddr and SockPort. If the component was spawned with a Reference parameter, this will be passed back as a key of the hashref.

The following events are sent to the calling session by the component:

=over

=item C<ident_agent_reply>

Returned when the component receives a USERID response from the identd. ARG0 is hashref, ARG1 is the opsys field and ARG2 is 
the userid or something else depending on whether the opsys field is set to 'OTHER' ( Don't blame me, read the RFC ).

=item C<ident_agent_error>

Returned when the component receives an ERROR response from the identd, there was some sort of communication error with the
remote host ( ie. no identd running ) or it had some other problem with making the connection to the other host. No matter. ARG0 is hashref, ARG1 is the type of error.

=back

=head1 AUTHOR

Chris Williams, E<lt>chris@bingosnet.co.uk<gt>

=head1 LICENSE

Copyright E<copy> Chris Williams.

This module may be used, modified, and distributed under the same terms as Perl itself. Please see the license that came with your Perl distribution for details.

=head1 SEE ALSO

RFC 1413 L<http://www.faqs.org/rfcs/rfc1413.html>

L<POE::Session>

L<POE::Component::Client::Ident>

=cut
