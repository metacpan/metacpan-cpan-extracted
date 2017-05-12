# $Id: UDP.pm 449 2004-12-27 01:37:33Z sungo $
package POE::Component::Server::Syslog::UDP;
$POE::Component::Server::Syslog::UDP::VERSION = '1.22';
#ABSTRACT: syslog udp server

use warnings;
use strict;

sub BINDADDR        () { '0.0.0.0' }
sub BINDPORT        () { 514 }
sub DATAGRAM_MAXLEN () { 1024 }  # syslogd defaults to this. as do most
                                 # libc implementations of syslog

use Params::Validate qw(validate_with);
use Carp qw(carp croak);

use POE;
use POE::Filter::Syslog;

use Socket;
use IO::Socket::INET;

sub spawn {
	my $class = shift;

	my %args = validate_with(
		params => \@_,
		spec => {
			InputState   => {
				type     => &Params::Validate::CODEREF,
				optional => 1,
				default  => sub {},
			},
			ErrorState   => {
				type     => &Params::Validate::CODEREF,
				optional => 1,
				default  => sub {},
			},
			BindAddress  => {
				type     => &Params::Validate::SCALAR,
				optional => 1,
				default  => BINDADDR,
			},
			BindPort     => {
				type     => &Params::Validate::SCALAR,
				optional => 1,
				default  => BINDPORT,
			},
			MaxLen       => {
				type     => &Params::Validate::SCALAR,
				optional => 1,
				default  => DATAGRAM_MAXLEN,
			},
            Alias         => {
            type     	  => &Params::Validate::SCALAR,
            optional      => 1,
            },
		},
	);

	$args{type} = 'udp';
	$args{filter} = POE::Filter::Syslog->new();

	my $sess = POE::Session->create(
		inline_states => {
			_start         => \&socket_start,
			_stop          => \&shutdown,

			select_read    => \&select_read,
			register	   => \&register,
			unregister	   => \&unregister,
			shutdown       => \&shutdown,

			client_input => $args{InputState},
			client_error => $args{ErrorState},

		},
		heap => \%args,
	);

	return $sess;
}


# This is a really good spot to discuss why this is using IO::Socket
# instead of a POE wheel of some variety for this. The answer, for once
# in my life, is pretty simple. POE::Wheel::SocketFactory doesn't support
# connectionless sockets as of the time of writing. In this scenario,
# there is no chance of IO::Socket blocking, unless IO::Socket decides
# to lose its mind. If it does THAT, there's not a whole hell of a lot
# left that's right in the world. :) except maybe pizza. well, good
# pizza like you find at Generous George's in Alexandria, VA. and rum.
# pretty much any rum. Um, but anyway...

sub socket_start {
	$_[HEAP]->{handle} = IO::Socket::INET->new(
		Blocking   => 0,
		LocalAddr  => $_[HEAP]->{BindAddress},
		LocalPort  => $_[HEAP]->{BindPort},
		Proto      => 'udp',
		ReuseAddr  => 1,
		SocketType => SOCK_DGRAM,
	);

	if (defined $_[HEAP]->{handle}) {
		$_[KERNEL]->select_read( $_[HEAP]->{handle}, 'select_read' );
	} else {
		croak "Unable to create UDP Listener: $!";
	}
	$_[KERNEL]->alias_set( $_[HEAP]->{Alias} ) if $_[HEAP]->{Alias};
	return;
}

sub select_read {
	my $message;
	my $remote_socket = $_[HEAP]->{handle}->recv($message, $_[HEAP]->{MaxLen}, 0 );
	if (defined $message) {
		$_[HEAP]->{filter}->get_one_start([ $message ]);
		my $records = [];
		while( ($records = $_[HEAP]->{filter}->get_one()) and (@$records > 0)) {
			if(defined $records and ref $records eq 'ARRAY') {
				foreach my $record (@$records) {
					if (my $addr = (sockaddr_in($remote_socket))[1]) {
						$record->{addr} = inet_ntoa($addr);
						if (my $host = gethostbyaddr($addr, AF_INET)) {
							$record->{host} = $host;
						}
					}

					$_[KERNEL]->yield( 'client_input', $record );
					$_[KERNEL]->post( $_, $_[HEAP]->{sessions}->{$_}->{inputevent}, $record )
						for keys %{ $_[HEAP]->{sessions} };
				}
			} else {
				$_[KERNEL]->yield( 'client_error', $message );
				$_[KERNEL]->post( $_, $_[HEAP]->{sessions}->{$_}->{errorevent}, $message )
					for grep { defined $_[HEAP]->{sessions}->{errorevent} }
						keys %{ $_[HEAP]->{sessions} };
			}
		}
	}
	return;
}

sub shutdown {
	my ($kernel,$heap) = @_[KERNEL,HEAP];
	if($heap->{handle}) {
		$kernel->select_read($heap->{handle});
		$heap->{handle}->close();
	}
	delete $heap->{handle};
	$kernel->alarm_remove_all();
    $kernel->alias_remove( $_ ) for $kernel->alias_list();
    $kernel->refcount_decrement( $_, __PACKAGE__ )
        for keys %{ $heap->{sessions} };
	return;
}

sub register {
  my ($kernel,$self,$sender) = @_[KERNEL,HEAP,SENDER];
  my $sender_id = $sender->ID();
  my %args;
  if ( ref $_[ARG0] eq 'HASH' ) {
    %args = %{ $_[ARG0] };
  }
  elsif ( ref $_[ARG0] eq 'ARRAY' ) {
    %args = @{ $_[ARG0] };
  }
  else {
    %args = @_[ARG0..$#_];
  }
  $args{lc $_} = delete $args{$_} for keys %args;
  unless ( $args{inputevent} ) {
    warn "No 'inputevent' argument supplied\n";
    return;
  }
  if ( defined $self->{sessions}->{ $sender_id } ) {
    $self->{sessions}->{ $sender_id } = \%args;
  }
  else {
    $self->{sessions}->{ $sender_id } = \%args;
    $kernel->refcount_increment( $sender_id, __PACKAGE__ );
  }
  return;
}

sub unregister {
  my ($kernel,$self,$sender) = @_[KERNEL,HEAP,SENDER];
  my $sender_id = $sender->ID();
  my %args;
  if ( ref $_[ARG0] eq 'HASH' ) {
    %args = %{ $_[ARG0] };
  }
  elsif ( ref $_[ARG0] eq 'ARRAY' ) {
    %args = @{ $_[ARG0] };
  }
  else {
    %args = @_[ARG0..$#_];
  }
  $args{lc $_} = delete $args{$_} for keys %args;
  my $data = delete $self->{sessions}->{ $sender_id };
  $kernel->refcount_decrement( $sender_id, __PACKAGE__ ) if $data;
  return;
}

1;


# sungo // vim: ts=4 sw=4 noexpandtab

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Server::Syslog::UDP - syslog udp server

=head1 VERSION

version 1.22

=head1 SYNOPSIS

    POE::Component::Server::Syslog::UDP->spawn(
        BindAddress => '127.0.0.1',
        BindPort    => '514',
        InputState  => \&input,
    );

    sub input {
        my $message = $_[ARG0];
        # .. do stuff ..
    }

=head1 DESCRIPTION

This component provides very simple syslog services for POE.

=for Pod::Coverage        BINDADDR
       BINDPORT
       DATAGRAM_MAXLEN
       select_read
       socket_start

=head1 CONSTRUCTOR

=head2 spawn()

Spawns a new listener. For a standalone syslog server you may specify
C<InputState> option to register a subroutine that will be called on
input events.

For integration with other POE Sessions and Components you may use the
C<register> and C<unregister> states to request that input events be
sent to your sessions.

C<spawn()> also accepts the following options:

=over 4

=item * InputState

A reference to a subroutine. This argument will become a POE state
that will be called when input from a syslog client has been recieved.

=item * BindAddress

The address to bind the listener to. Defaults to 0.0.0.0

=item * BindPort

The port number to bind the listener to. Defaults to 514

=item * MaxLen

The maximum length of a datagram. Defaults to 1024, which is the usual
default of most syslog and syslogd implementations.

=item * ErrorState

An optional code reference. This becomes a POE state that will get
called when the component recieves a message it cannot parse. The
erroneous message is passed in as ARG0.

=item * Alias

Optionally specify that the component use the supplied alias.

=back

=head2 InputState

The ClientInput routine obtained by C<spawn()> will be passed a hash
reference as ARG0 containing the following information:

=over 4

=item * time

The time of the datagram (as specified by the datagram itself)

=item * pri

The priority of message.

=item * facility

The "facility" number decoded from the pri.

=item * severity

The "severity" number decoded from the pri.

=item * addr

The remote address of the source in dotted-decimal notation.

=item * host

The hostname of the source, if available.

=item * msg

The message itself. This often includes a process name, pid number, and
user name.

=back

=head1 INPUT EVENTS

These are events that this component will accept.

=head2 register

This will register the sending session to receive InputEvent and ErrorEvents from the
component.

Takes a number of parameters:

=over 4

=item * InputEvent

Mandatory parameter, the name of the event in the registering session that will be triggered
for input from clients. ARG0 will contain a hash reference. See C<InputHandler> for details.

=item * ErrorEvent

Optional parameter, the name of the event in the registering session that will be triggered
for input that cannot be parsed. ARG0 will contain the erroneous message.

=back

The component will increment the refcount of the calling session to make sure it hangs around for events.
Therefore, you should use either C<unregister> or C<shutdown> to terminate registered sessions.

=head2 unregister

This will unregister the sending session from receiving events.

=head2 shutdown

Termintes the component.

=head1 AUTHOR

Matt Cashner (sungo@pobox.com)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Matt Cashner (sungo@pobox.com).

This is free software, licensed under:

  The (three-clause) BSD License

=cut
