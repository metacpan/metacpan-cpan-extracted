# $Id: TCP.pm 446 2004-12-27 00:57:57Z sungo $
package POE::Component::Server::Syslog::TCP;
$POE::Component::Server::Syslog::TCP::VERSION = '1.22';
#ABSTRACT: syslog tcp server

use warnings;
use strict;

sub BINDADDR        () { '0.0.0.0' }
sub BINDPORT        () { 514 }
sub DATAGRAM_MAXLEN () { 1024 }  # syslogd defaults to this. as do most
                                 # libc implementations of syslog

use Params::Validate qw(validate_with);
use Carp qw(carp croak);
use Socket;

use POE qw(
	Driver::SysRW
	Wheel::SocketFactory
	Wheel::ReadWrite
	Filter::Syslog
);


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
			Alias  		 => {
				type     => &Params::Validate::SCALAR,
				optional => 1,
			},
		},
	);

	$args{type} = 'tcp';
	$args{filter} = POE::Filter::Syslog->new();

	my $sess = POE::Session->create(
		inline_states => {
			_start         => \&start,
			_stop          => \&shutdown,

			socket_connect => \&socket_connect,
			socket_error   => \&socket_error,
			socket_input   => \&socket_input,
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

sub start {
	$_[HEAP]->{socketfactory} = POE::Wheel::SocketFactory->new(
		BindAddress  => $_[HEAP]->{BindAddress},
		BindPort     => $_[HEAP]->{BindPort},
		SuccessEvent => 'socket_connect',
		FailureEvent => 'client_error',
		ListenQueue  => $_[HEAP]->{MaxLen},
		Reuse        => 'yes',
	);

	unless($_[HEAP]->{socketfactory}) {
		croak("Unable to setup socketfactory");
	}
	$_[KERNEL]->alias_set( $_[HEAP]->{Alias} ) if $_[HEAP]->{Alias};
    return;
}

sub socket_connect {
	my $handle = $_[ARG0];
	my $host;

	if( ( sockaddr_in( getpeername($handle) ) )[1]) {
		$host = gethostbyaddr( ( sockaddr_in( getpeername($handle) ) )[1], AF_INET );
	}
    else {
		$host = '[unknown]';
	}

	my $wheel = POE::Wheel::ReadWrite->new(
		Handle     => $handle,
		Driver     => POE::Driver::SysRW->new(),
		Filter     => POE::Filter::Syslog->new(),
		InputEvent => 'socket_input',
		ErrorEvent => 'socket_error',
	);

	$_[HEAP]->{wheels}->{ $wheel->ID } = {
		wheel => $wheel,
		host  => $host,
	};
    return;
}

sub socket_error {
	my ($errop, $errnum, $errstr, $wid) = @_[ARG0 .. ARG3];
	unless( ($errnum == 0) && ($errop eq 'read') ) {
		$_[KERNEL]->yield( 'client_error', $errop, $errnum, $errstr );
	}
	delete $_[HEAP]->{wheels}->{ $wid };
    return;
}

sub socket_input {
	my ($input, $wid) = @_[ARG0, ARG1];
	my $info = $_[HEAP]->{wheels}->{ $wid };

	if(ref $input && ref $input eq 'ARRAY') {
		foreach my $record (@{ $input }) {
			$input->{host} = $info->{host};
			$_[KERNEL]->yield( 'client_input', $record );
		}
	}
    elsif(ref $input && ref $input eq 'HASH') {
		$input->{host} = $info->{host};
		$_[KERNEL]->yield( 'client_input', $input );
		$_[KERNEL]->post( $_, $_[HEAP]->{sessions}->{$_}->{inputevent}, $input )
			for keys %{ $_[HEAP]->{sessions} };
	}
    else {
		$_[KERNEL]->yield( 'client_error', $input );
		$_[KERNEL]->post( $_, $_[HEAP]->{sessions}->{$_}->{errorevent}, $input )
			for grep { defined $_[HEAP]->{sessions}->{errorevent} }
			    keys %{ $_[HEAP]->{sessions} };
	}
    return;
}

sub shutdown {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
	if($heap->{socketfactory}) {
		$heap->{socketfactory}->pause_accept();
		delete $heap->{socketfactory};
	}
	delete $heap->{wheels};
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

POE::Component::Server::Syslog::TCP - syslog tcp server

=head1 VERSION

version 1.22

=head1 SYNOPSIS

    POE::Component::Server::Syslog::TCP->spawn(
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
       socket_connect
       socket_error
       socket_input
       start

=head1 CONSTRUCTOR

=head2 spawn()

Spawns a new listener. For a standalone syslog server you may specify
C<InputState> option to register a subroutine that will be called on
input events.

For integration with other POE Sessions and Components you may use the
C<register> and C<unregister> states to request that input events be
sent to your sessions.

Returns the POE::Session object it creates.

C<spawn()> accepts the following options:

=over 4

=item * InputState

Requires one argument, C<InputState>, which must
be a reference to a subroutine. This argument will become a POE state
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

=item * host

The host that sent the message.

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
