package POE::Component::Server::JSONUnix::Client;

use strict;
use warnings;
use v5.10;

use Carp          qw(carp croak);
use Socket        qw(PF_UNIX SOCK_STREAM);
use File::Temp 0.2310 ();    # 0.2310 for tempfile's PERMS option
use JSON::MaybeXS ();

use POE qw(
	Wheel::SocketFactory
	Wheel::ReadWrite
	Filter::Line
	Driver::SysRW
);

our $VERSION = '0.1.0';

# Refcount tag used to keep event-style requesters alive while a reply is
# outstanding.
use constant REFCOUNT_TAG => 'jsonunix_client_pending';

=head1 NAME

POE::Component::Server::JSONUnix::Client - POE client for POE::Component::Server::JSONUnix

=head1 SYNOPSIS

    use POE;
    use POE::Component::Server::JSONUnix::Client;

    my $client = POE::Component::Server::JSONUnix::Client->spawn(
        socket_path => '/tmp/app.sock',
        auto_auth   => 1,
        on_auth     => sub {
            my ($client, $response) = @_;
            die $response->{error} if $response->{status} ne 'ok';

            $client->call(
                command  => 'whoami',
                callback => sub {
                    my ($response) = @_;
                    print "I am $response->{result}{username}\n";
                    $client->shutdown;
                },
            );
        },
    );

    $poe_kernel->run;

=head1 DESCRIPTION

An event-driven client for L<POE::Component::Server::JSONUnix>. It connects to
the server's Unix domain socket, frames requests as newline-delimited JSON,
assigns each request an C<id>, and dispatches each response back to the caller
by matching the echoed C<id> -- so any number of requests may be in flight at
once.

It also knows how to complete the server's Unix-ownership authentication
challenge (see L</authenticate>).

=head1 CONSTRUCTOR

=head2 spawn

    my $client = POE::Component::Server::JSONUnix::Client->spawn(%args);

Creates the client's POE session and returns the client object. Recognised
arguments:

=head3 socket_path

Required. Filesystem path of the server's Unix domain socket.

=head3 alias

POE session alias. Defaults to C<json_unix_client>. Set this if you run more
than one client in a single process.

=head3 auto_connect

Connect immediately from C<spawn>. Defaults to true. When false, call
L</connect> yourself.

=head3 auto_auth

Run L</authenticate> automatically as soon as the connection is up. Defaults
to false. The outcome is delivered to C<on_auth>.

=head3 request_timeout

Default per-request timeout in seconds. A request that receives no response
in time is answered locally with
C<< {status => 'error', error => 'request timed out'} >>. No timeout by
default. Can be overridden per request.

=head3 on_connect

Code reference called as C<< $cb->($client) >> once the connection is
established.

=head3 on_auth

Code reference called as C<< $cb->($client, $response) >> when an
C<auto_auth> handshake completes (successfully or not).

=head3 on_disconnect

Code reference called as C<< $cb->($client, $reason) >> when the connection
is lost or closed.

=head3 on_error

Code reference called as C<< $cb->($operation, $errnum, $errstr) >> on
connect and I/O errors. A normal EOF from the server is not reported here
(it is reported via C<on_disconnect>).

=head3 on_notice

Code reference called as C<< $cb->($client, $response) >> for any server
message that cannot be matched to a pending request. This happens when:

=over 4

=item *

the message has no C<id> at all -- e.g. the server's error response to a
request it could not parse an C<id> out of, or an unsolicited message pushed
by a server-side handler;

=item *

the C<id> is one this client is no longer waiting on -- most notably a
response that arrives I<after> its timeout already fired locally (see
L</call>), or a duplicate response to a request that was already answered.

=back

Unmatched messages are dropped silently if this is not set. A response
delivered here is never also delivered to the original request's C<callback>
or C<event> -- each request is answered exactly once.

=cut

sub spawn {
	my ( $class, %args ) = @_;

	my $path = delete $args{socket_path}
		or croak "spawn() requires a 'socket_path' argument";

	my $self = bless {
		socket_path     => $path,
		alias           => ( delete $args{alias} ) // 'json_unix_client',
		auto_connect    => ( delete $args{auto_connect} ) // 1,
		auto_auth       => ( delete $args{auto_auth} ) // 0,
		request_timeout => delete $args{request_timeout},                  # seconds (optional)
		on_connect      => delete $args{on_connect},
		on_auth         => delete $args{on_auth},
		on_disconnect   => delete $args{on_disconnect},
		on_error        => delete $args{on_error},
		on_notice       => delete $args{on_notice},
		json            => JSON::MaybeXS->new(
			utf8         => 1,
			canonical    => 1,
			allow_nonref => 0,
		),
		next_request_id => 1,
		pending         => {},       # request id => record
		queue           => [],       # records created while still connecting
		connecting      => 0,
		connected       => 0,
		auth            => undef,    # {uid, username} after a successful handshake
	}, $class;

	POE::Session->create(
		object_states => [
			$self => {
				_start            => '_poe_start',
				connect           => '_poe_connect',
				disconnect        => '_poe_disconnect',
				shutdown          => '_poe_shutdown',
				got_socket        => '_poe_got_socket',
				connect_error     => '_poe_connect_error',
				server_input      => '_poe_server_input',
				server_error      => '_poe_server_error',
				send_request      => '_poe_send_request',
				request_timed_out => '_poe_request_timed_out',
			},
		],
	);

	return $self;
} ## end sub spawn

#--- public methods ----------------------------------------------------------

=head1 METHODS

=head2 connect

    $client->connect;

Begin connecting to the server. A no-op if already connected or connecting.
Completion is signalled through C<on_connect> (or C<on_error> on failure).
May be called again after a disconnect.

=head2 disconnect

    $client->disconnect;

Drop the connection. Every request still awaiting a response is answered
locally with an error.

=head2 shutdown

    $client->shutdown;

Disconnect, release the session alias, and let the session end.

=cut

sub connect    { $poe_kernel->post( $_[0]{session_id}, 'connect' );    return }
sub disconnect { $poe_kernel->post( $_[0]{session_id}, 'disconnect' ); return }
sub shutdown   { $poe_kernel->post( $_[0]{session_id}, 'shutdown' );   return }

=head2 call

    my $request_id = $client->call(
        command  => 'add',
        args     => { numbers => [ 1, 2, 3 ] },
        callback => sub { my ($response) = @_; ... },
    );

Send a request. Returns the C<id> assigned to it.

With neither C<callback> nor C<event> the request is fire-and-forget: it is
sent, and its response is discarded when it arrives.

Every request is eventually answered exactly once: by the server, by the
timeout, or with a local error if the connection is (or comes) down. Requests
made while a connection attempt is in progress are queued and sent once it
completes.

Arguments:

=head3 command

Required. The command name. C<cmd> is accepted as an alias.

=head3 args

Arbitrary payload for the command's handler.

=head3 callback

Code reference invoked as C<< $cb->($response, $context) >> with the full
decoded response envelope, e.g.
C<< {id => 7, status => 'ok', result => {...}} >>.

=head3 event

Instead of C<callback>, the name of an event to post back to the calling
session, with the response as C<ARG0> and C<$context> as C<ARG1>. The
requesting session is kept alive (via a reference count) until the response
arrives. Must be used from inside a running POE session; C<session> may be
given to direct the event elsewhere.

=head3 context

An opaque value handed back with the response, for correlating state on your
side.

=head3 timeout

Per-request timeout in seconds, overriding C<request_timeout>.

A note on timeouts: a timeout is a local judgement, not a cancellation. The
server knows nothing about it and may still be working on the request; there
is no protocol message to withdraw one. When a timeout fires, the request's
C<callback> or C<event> receives C<< {status => 'error', error => 'request
timed out', id => $id} >> and the request is forgotten. If the server's real
response shows up later, it no longer matches anything pending and is routed
to C<on_notice> (carrying its C<id>, so it can still be recognised there) --
it will never be delivered to the original C<callback> or C<event>, which
have already been answered. Set C<on_notice> if late results matter to you;
otherwise they are dropped.

=cut

sub call {
	my ( $self, %req ) = @_;

	my $command = delete $req{command} // delete $req{cmd};
	croak "call() requires a 'command' argument"
		unless defined $command;

	my $args    = delete $req{args};
	my $timeout = ( delete $req{timeout} ) // $self->{request_timeout};

	my $respond = $self->_make_responder(%req);

	my $request_id = $self->{next_request_id}++;
	my $record     = {
		id      => $request_id,
		respond => $respond,
		timeout => $timeout,
		request => {
			command => $command,
			id      => $request_id,
			( defined $args ? ( args => $args ) : () ),
		},
	};

	$poe_kernel->post( $self->{session_id}, send_request => $record );
	return $request_id;
} ## end sub call

=head2 authenticate

    $client->authenticate(
        callback => sub {
            my ($response) = @_;
            # {status => 'ok', result => {uid => 1000, username => 'alice'}}
        },
    );

Perform the server's Unix-ownership challenge: call C<auth_start>, write the
returned cookie to a fresh file in the server's C<temp_dir> (the OS stamps the
file with this process's effective UID, which is the proof the server checks),
then call C<auth_verify> and clean the file up.

Takes the same C<callback> / C<event> / C<context> arguments as L</call>. The
response delivered is the C<auth_verify> response on success, or a synthesised
C<< {status => 'error', ...} >> envelope if any step fails. After success,
L</authenticated>, L</uid> and L</username> reflect the verified identity.

=cut

sub authenticate {
	my ( $self, %opt ) = @_;

	my $done = $self->_make_responder(%opt);

	$self->call(
		command  => 'auth_start',
		callback => sub {
			my ($challenge) = @_;

			unless ( ( $challenge->{status} // '' ) eq 'ok' ) {
				$done->(
					{
						status => 'error',
						error  => 'auth_start failed: ' . ( $challenge->{error} // 'unknown error' ),
					}
				);
				return;
			} ## end unless ( ( $challenge->{status} // '' ) eq 'ok')

			my $cookie   = $challenge->{result}{cookie}   // '';
			my $temp_dir = $challenge->{result}{temp_dir} // '';
			unless ( length $cookie && length $temp_dir && -d $temp_dir ) {
				$done->(
					{
						status => 'error',
						error  => 'auth_start returned an unusable cookie or temp_dir',
					}
				);
				return;
			} ## end unless ( length $cookie && length $temp_dir &&...)

			# PERMS creates the file as 0644 from the start rather than
			# File::Temp's 0600 default: the server may run as another
			# unprivileged user and must be able to read it. The proof is the
			# file's ownership, not its secrecy -- the cookie is single-use
			# and the file is unlinked on verify -- so world-readable is
			# acceptable and there is no window where the file exists with
			# the wrong mode.
			my ( $fh, $cookie_path ) = eval {
				File::Temp::tempfile(
					'jsonunix_auth_XXXXXX',
					DIR    => $temp_dir,
					UNLINK => 0,
					PERMS  => 0644,
				);
			};
			unless ($fh) {
				$done->(
					{
						status => 'error',
						error  => "could not create cookie file in $temp_dir: " . ( $@ || $! ),
					}
				);
				return;
			} ## end unless ($fh)
			print {$fh} $cookie;
			close $fh;

			$self->call(
				command  => 'auth_verify',
				args     => { path => $cookie_path },
				callback => sub {
					my ($verdict) = @_;
					unlink $cookie_path;    # server unlinks it; clean up if it did not
					if ( ( $verdict->{status} // '' ) eq 'ok' ) {
						$self->{auth} = {
							uid      => $verdict->{result}{uid},
							username => $verdict->{result}{username},
							groups   => $verdict->{result}{groups} // [],
						};
					}
					$done->($verdict);
					return;
				},
			);
			return;
		},
	);
	return;
} ## end sub authenticate

=head2 connected

True while a connection to the server is up.

=head2 authenticated

True after a successful L</authenticate> on the current connection.

=head2 uid

=head2 username

The verified identity, or C<undef> before authentication. Cleared on
disconnect.

=head2 groups

Array reference of the verified user's group names, or C<undef> before
authentication. Empty unless the server has a permission policy configured
(only then does its C<auth_verify> report groups). Cleared on disconnect.

=cut

sub connected     { return $_[0]{connected} }
sub authenticated { return defined $_[0]{auth} }
sub uid           { return $_[0]{auth} ? $_[0]{auth}{uid} : undef }
sub username      { return $_[0]{auth} ? $_[0]{auth}{username} : undef }
sub groups        { return $_[0]{auth} ? $_[0]{auth}{groups} : undef }

#--- response routing --------------------------------------------------------

# Normalise callback/event/context into a single coderef that delivers one
# response envelope. Called in the requester's context so that
# get_active_session() names the right session for event-style delivery.
sub _make_responder {
	my ( $self, %opt ) = @_;

	my $callback = delete $opt{callback};
	my $event    = delete $opt{event};
	my $context  = delete $opt{context};

	if ( defined $callback ) {
		croak "'callback' must be a code reference"
			unless ref $callback eq 'CODE';
		return sub { $callback->( $_[0], $context ); return };
	}

	if ( defined $event ) {
		my $session_id = $opt{session} // $poe_kernel->get_active_session->ID;
		$poe_kernel->refcount_increment( $session_id, REFCOUNT_TAG );
		return sub {
			$poe_kernel->post( $session_id, $event, $_[0], $context );
			$poe_kernel->refcount_decrement( $session_id, REFCOUNT_TAG );
			return;
		};
	} ## end if ( defined $event )

	return sub { };    # fire and forget
} ## end sub _make_responder

#--- POE: session lifecycle --------------------------------------------------

sub _poe_start {
	my ( $self, $kernel, $session ) = @_[ OBJECT, KERNEL, SESSION ];
	$self->{session_id} = $session->ID;
	$kernel->alias_set( $self->{alias} );
	$kernel->yield('connect') if $self->{auto_connect};
	return;
}

sub _poe_shutdown {
	my ( $self, $kernel ) = @_[ OBJECT, KERNEL ];
	$self->_drop_connection('client shutting down');
	$kernel->alias_remove( $self->{alias} );
	return;
}

#--- POE: connection management ----------------------------------------------

sub _poe_connect {
	my ($self) = $_[OBJECT];

	return if $self->{connected} || $self->{connecting};

	$self->{connecting} = 1;
	$self->{connector}  = POE::Wheel::SocketFactory->new(
		SocketDomain  => PF_UNIX,
		SocketType    => SOCK_STREAM,
		RemoteAddress => $self->{socket_path},
		SuccessEvent  => 'got_socket',
		FailureEvent  => 'connect_error',
	);
	return;
} ## end sub _poe_connect

sub _poe_got_socket {
	my ( $self, $kernel, $socket ) = @_[ OBJECT, KERNEL, ARG0 ];

	delete $self->{connector};
	$self->{connecting} = 0;
	$self->{connected}  = 1;

	$self->{wheel} = POE::Wheel::ReadWrite->new(
		Handle     => $socket,
		Driver     => POE::Driver::SysRW->new,
		Filter     => POE::Filter::Line->new( Literal => "\n" ),
		InputEvent => 'server_input',
		ErrorEvent => 'server_error',
	);

	# Flush anything queued while the connection was being made.
	my @queued = splice @{ $self->{queue} };
	$kernel->yield( send_request => $_ ) for @queued;

	$self->{on_connect}->($self) if $self->{on_connect};

	if ( $self->{auto_auth} ) {
		$self->authenticate(
			callback => sub {
				my ($response) = @_;
				$self->{on_auth}->( $self, $response ) if $self->{on_auth};
				return;
			},
		);
	} ## end if ( $self->{auto_auth} )
	return;
} ## end sub _poe_got_socket

sub _poe_connect_error {
	my ( $self, $op, $errnum, $errstr ) = @_[ OBJECT, ARG0, ARG1, ARG2 ];

	$self->{on_error}->( "connect:$op", $errnum, $errstr ) if $self->{on_error};
	$self->_drop_connection("connect failed during $op: $errstr");
	return;
}

sub _poe_disconnect {
	my ($self) = $_[OBJECT];
	my $was_connected = $self->{connected};
	$self->_drop_connection('disconnected');
	$self->{on_disconnect}->( $self, 'disconnected' )
		if $was_connected && $self->{on_disconnect};
	return;
}

sub _poe_server_error {
	my ( $self, $op, $errnum, $errstr ) = @_[ OBJECT, ARG0, ARG1, ARG2 ];

	# operation 'read' with errnum 0 is a normal EOF (server hung up).
	my $eof    = ( $op eq 'read' && $errnum == 0 );
	my $reason = $eof ? 'server closed connection' : "$op error: $errstr ($errnum)";

	$self->{on_error}->( $op, $errnum, $errstr ) if $self->{on_error} && !$eof;
	$self->_drop_connection($reason);
	$self->{on_disconnect}->( $self, $reason ) if $self->{on_disconnect};
	return;
} ## end sub _poe_server_error

# Tear down the connection state and answer every outstanding request with an
# error so no caller is left waiting forever.
sub _drop_connection {
	my ( $self, $reason ) = @_;

	delete $self->{wheel};
	delete $self->{connector};
	$self->{connecting} = 0;
	$self->{connected}  = 0;
	$self->{auth}       = undef;

	my @records = ( ( splice @{ $self->{queue} } ), values %{ $self->{pending} } );
	%{ $self->{pending} } = ();

	for my $record (@records) {
		$poe_kernel->alarm_remove( $record->{alarm_id} )
			if defined $record->{alarm_id};
		$record->{respond}->( { status => 'error', error => $reason, id => $record->{id} } );
	}
	return;
} ## end sub _drop_connection

#--- POE: request / response flow --------------------------------------------

sub _poe_send_request {
	my ( $self, $kernel, $record ) = @_[ OBJECT, KERNEL, ARG0 ];

	unless ( $self->{connected} ) {
		if ( $self->{connecting} ) {
			push @{ $self->{queue} }, $record;
			return;
		}
		$record->{respond}->( { status => 'error', error => 'not connected', id => $record->{id} } );
		return;
	} ## end unless ( $self->{connected} )

	my $json = eval { $self->{json}->encode( $record->{request} ) };
	unless ( defined $json ) {
		$record->{respond}->(
			{
				status => 'error',
				error  => 'request could not be serialised as JSON',
				id     => $record->{id},
			}
		);
		return;
	} ## end unless ( defined $json )

	$self->{pending}{ $record->{id} } = $record;
	if ( defined $record->{timeout} ) {
		$record->{alarm_id} = $kernel->delay_set( request_timed_out => $record->{timeout}, $record->{id} );
	}
	$self->{wheel}->put($json);    # Filter::Line appends the trailing newline
	return;
} ## end sub _poe_send_request

sub _poe_server_input {
	my ( $self, $kernel, $line ) = @_[ OBJECT, KERNEL, ARG0 ];

	return unless defined $line && $line =~ /\S/;

	my $response;
	unless ( eval { $response = $self->{json}->decode($line); 1 }
		&& ref $response eq 'HASH' )
	{
		carp "unparsable line from server: $line";
		return;
	}

	my $record =
		defined $response->{id}
		? delete $self->{pending}{ $response->{id} }
		: undef;

	unless ($record) {
		# No id, or an id we are not waiting on (e.g. the response arrived
		# after its timeout already fired).
		$self->{on_notice}->( $self, $response ) if $self->{on_notice};
		return;
	}

	$kernel->alarm_remove( $record->{alarm_id} )
		if defined $record->{alarm_id};
	$record->{respond}->($response);
	return;
} ## end sub _poe_server_input

sub _poe_request_timed_out {
	my ( $self, $request_id ) = @_[ OBJECT, ARG0 ];

	my $record = delete $self->{pending}{$request_id} or return;
	$record->{respond}->( { status => 'error', error => 'request timed out', id => $request_id } );
	return;
}

1;

__END__

=pod

=head1 AUTHENTICATION

The server's L<user verification
scheme|POE::Component::Server::JSONUnix/"USER VERIFICATION"> proves which Unix
user is on the other end of the socket by file ownership rather than by
password. This component implements the client half:

=over 4

=item 1. Send C<auth_start>; receive a one-time C<cookie> and the server's C<temp_dir>.

=item 2. Create a fresh file in C<temp_dir> (via L<File::Temp>) containing the cookie. The kernel records this process's effective UID as the file's owner. The file is created with mode 0644 so a server running as a different unprivileged user can read it -- the proof lies in the file's ownership, not in keeping its contents secret.

=item 3. Send C<auth_verify> with the file's path. The server checks the cookie, C<stat>s the file for the owning UID, and unlinks it.

=back

Run it explicitly with L</authenticate>, or set C<auto_auth> to have it happen
on every (re)connect. Note that authentication state lives on the connection:
after a disconnect and reconnect the handshake must be performed again, which
C<auto_auth> handles for you.

The client and server must share a filesystem (and the same C<temp_dir>) for
this to work -- which is the natural state of affairs for a Unix-socket pair.

=head1 SEE ALSO

L<POE::Component::Server::JSONUnix>, L<POE>, L<POE::Wheel::SocketFactory>,
L<POE::Wheel::ReadWrite>, L<JSON::MaybeXS>.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
