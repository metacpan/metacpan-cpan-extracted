package POE::Component::Server::JSONUnix::BlockingClient;

use strict;
use warnings;
use v5.10;

use Carp             qw(croak);
use Socket           qw(SOCK_STREAM);
use IO::Socket::UNIX ();
use IO::Select       ();
use File::Temp 0.2310 ();    # 0.2310 for tempfile's PERMS option
use JSON::MaybeXS ();

our $VERSION = '0.1.0';

=head1 NAME

POE::Component::Server::JSONUnix::BlockingClient - simple blocking (non-POE) client for POE::Component::Server::JSONUnix

=head1 SYNOPSIS

    use POE::Component::Server::JSONUnix::BlockingClient;

    my $client = POE::Component::Server::JSONUnix::BlockingClient->new(
        socket_path => '/tmp/app.sock',
    );

    my $auth = $client->authenticate;
    die $auth->{error} if $auth->{status} ne 'ok';

    my $response = $client->call(
        command => 'add',
        args    => { numbers => [ 1, 2, 3 ] },
    );
    die $response->{error} if $response->{status} ne 'ok';
    print "sum is $response->{result}{sum}\n";

    $client->disconnect;

=head1 DESCRIPTION

A minimal synchronous client for L<POE::Component::Server::JSONUnix>. Unlike
L<POE::Component::Server::JSONUnix::Client> it does not use POE at all: each
L</call> writes one newline-delimited JSON request to the server's Unix domain
socket and blocks until the matching response arrives (or a timeout expires).

This is the right tool for command-line utilities, cron jobs, and other
plain-procedural programs that just want to ask a running daemon a question.
If you need concurrent requests, callbacks, or to live inside an event loop,
use the POE client instead.

It also knows how to complete the server's Unix-ownership authentication
challenge (see L</authenticate>).

=head1 CONSTRUCTOR

=head2 new

    my $client = POE::Component::Server::JSONUnix::BlockingClient->new(%args);

Creates the client and (by default) connects. Recognised arguments:

=head3 socket_path

Required. Filesystem path of the server's Unix domain socket.

=head3 auto_connect

Connect immediately from C<new>, croaking on failure. Defaults to true. When
false, call L</connect> yourself.

=head3 timeout

Default per-request timeout in seconds (fractional values are fine). A
request that receives no response in time returns
C<< {status => 'error', error => 'request timed out'} >>. No timeout by
default: L</call> blocks until the server answers or hangs up. Can be
overridden per request.

=head3 on_notice

Code reference called as C<< $cb->($client, $response) >> for any server
message that cannot be matched to the request currently being waited on: a
message with no C<id>, or one whose C<id> is not the awaited one (most
notably a response arriving I<after> its request already timed out locally).
Unmatched messages are dropped silently if this is not set.

=cut

sub new {
	my ( $class, %args ) = @_;

	my $path = delete $args{socket_path}
		or croak "new() requires a 'socket_path' argument";

	my $self = bless {
		socket_path => $path,
		timeout     => delete $args{timeout},      # seconds (optional)
		on_notice   => delete $args{on_notice},
		json        => JSON::MaybeXS->new(
			utf8         => 1,
			canonical    => 1,
			allow_nonref => 0,
		),
		next_request_id => 1,
		socket          => undef,
		read_buffer     => '',
		auth            => undef,                  # {uid, username} after a successful handshake
	}, $class;

	my $auto_connect = ( delete $args{auto_connect} ) // 1;
	$self->connect if $auto_connect;

	return $self;
} ## end sub new

=head1 METHODS

=head2 connect

    $client->connect;

Connect to the server. A no-op if already connected. Croaks if the connection
cannot be made. Returns the client object. May be called again after a
disconnect.

=cut

sub connect {
	my ($self) = @_;

	return $self if $self->{socket};

	my $socket = IO::Socket::UNIX->new(
		Type => SOCK_STREAM,
		Peer => $self->{socket_path},
	) or croak "cannot connect to '$self->{socket_path}': $!";
	$socket->autoflush(1);

	$self->{socket}      = $socket;
	$self->{read_buffer} = '';
	return $self;
} ## end sub connect

=head2 disconnect

    $client->disconnect;

Close the connection. A no-op if not connected. Authentication state lives on
the connection, so it is cleared here; after a reconnect the handshake must be
performed again.

=cut

sub disconnect {
	my ($self) = @_;
	close delete $self->{socket} if $self->{socket};
	$self->{read_buffer} = '';
	$self->{auth}        = undef;
	return;
}

=head2 call

    my $response = $client->call(
        command => 'add',
        args    => { numbers => [ 1, 2, 3 ] },
    );

Send a request and block until its response arrives. Returns the full decoded
response envelope, e.g. C<< {id => 7, status => 'ok', result => {...}} >>.

Failures are reported in-band, as C<< {status => 'error', error => ...} >>
envelopes just as server-side errors are -- a timeout, a connection that is
(or comes) down mid-request, or an unserialisable request all produce one, so
checking C<< $response->{status} >> covers everything. Note that a timeout is
a local judgement only: the server may still be working on the request, and
its late response is routed to C<on_notice> (or dropped) when it eventually
arrives during a later C<call>.

Croaks only on usage errors (a missing C<command>).

Arguments:

=head3 command

Required. The command name. C<cmd> is accepted as an alias.

=head3 args

Arbitrary payload for the command's handler.

=head3 timeout

Per-request timeout in seconds, overriding the constructor's C<timeout>.

=cut

sub call {
	my ( $self, %req ) = @_;

	my $command = delete $req{command} // delete $req{cmd};
	croak "call() requires a 'command' argument"
		unless defined $command;

	my $args    = delete $req{args};
	my $timeout = ( delete $req{timeout} ) // $self->{timeout};

	my $request_id = $self->{next_request_id}++;

	unless ( $self->{socket} ) {
		return { status => 'error', error => 'not connected', id => $request_id };
	}

	my $json = eval {
		$self->{json}->encode(
			{
				command => $command,
				id      => $request_id,
				( defined $args ? ( args => $args ) : () ),
			}
		);
	};
	unless ( defined $json ) {
		return {
			status => 'error',
			error  => 'request could not be serialised as JSON',
			id     => $request_id,
		};
	}

	unless ( print { $self->{socket} } $json, "\n" ) {
		my $error = "could not send request: $!";
		$self->disconnect;
		return { status => 'error', error => $error, id => $request_id };
	}

	my $deadline = defined $timeout ? time() + $timeout : undef;

	while (1) {
		my $line = $self->_read_line($deadline);
		unless ( defined $line ) {
			my $error = delete $self->{read_error};
			if ( $error eq 'timeout' ) {
				return { status => 'error', error => 'request timed out', id => $request_id };
			}
			$self->disconnect;
			return { status => 'error', error => $error, id => $request_id };
		}

		next unless $line =~ /\S/;

		my $response;
		unless ( eval { $response = $self->{json}->decode($line); 1 }
			&& ref $response eq 'HASH' )
		{
			# Unparsable server output cannot be correlated to anything;
			# treat it like an id-less message.
			next;
		}

		return $response
			if defined $response->{id} && $response->{id} eq $request_id;

		# No id, or an id we are not waiting on (e.g. a response that arrived
		# after its request already timed out).
		$self->{on_notice}->( $self, $response ) if $self->{on_notice};
	} ## end while (1)
} ## end sub call

# Return the next newline-terminated line from the socket (without its
# newline), or undef with $self->{read_error} set to 'timeout', 'server
# closed connection', or a read error description.
sub _read_line {
	my ( $self, $deadline ) = @_;

	while (1) {
		return $1 if $self->{read_buffer} =~ s/\A(.*?)\n//;

		if ( defined $deadline ) {
			my $remaining = $deadline - time();
			if ( $remaining <= 0
				|| !IO::Select->new( $self->{socket} )->can_read($remaining) )
			{
				$self->{read_error} = 'timeout';
				return undef;
			}
		}

		my $read = sysread( $self->{socket}, my $chunk, 65536 );
		unless ($read) {
			$self->{read_error} =
				defined $read
				? 'server closed connection'
				: "read error: $!";
			return undef;
		}
		$self->{read_buffer} .= $chunk;
	} ## end while (1)
} ## end sub _read_line

=head2 authenticate

    my $response = $client->authenticate;
    die $response->{error} if $response->{status} ne 'ok';

Perform the server's Unix-ownership challenge: call C<auth_start>, write the
returned cookie to a fresh file in the server's C<temp_dir> (the OS stamps the
file with this process's effective UID, which is the proof the server checks),
then call C<auth_verify> and clean the file up.

Accepts an optional C<timeout>, applied to each of the two requests. Returns
the C<auth_verify> response envelope on success, or a synthesised
C<< {status => 'error', ...} >> envelope if any step fails. After success,
L</authenticated>, L</uid> and L</username> reflect the verified identity.

=cut

sub authenticate {
	my ( $self, %opt ) = @_;

	my $timeout = delete $opt{timeout};

	my $challenge = $self->call(
		command => 'auth_start',
		( defined $timeout ? ( timeout => $timeout ) : () ),
	);
	unless ( ( $challenge->{status} // '' ) eq 'ok' ) {
		return {
			status => 'error',
			error  => 'auth_start failed: ' . ( $challenge->{error} // 'unknown error' ),
		};
	}

	my $cookie   = $challenge->{result}{cookie}   // '';
	my $temp_dir = $challenge->{result}{temp_dir} // '';
	unless ( length $cookie && length $temp_dir && -d $temp_dir ) {
		return {
			status => 'error',
			error  => 'auth_start returned an unusable cookie or temp_dir',
		};
	}

	# PERMS creates the file as 0644 from the start rather than File::Temp's
	# 0600 default: the server may run as another unprivileged user and must
	# be able to read it. The proof is the file's ownership, not its secrecy
	# -- the cookie is single-use and the file is unlinked on verify -- so
	# world-readable is acceptable and there is no window where the file
	# exists with the wrong mode.
	my ( $fh, $cookie_path ) = eval {
		File::Temp::tempfile(
			'jsonunix_auth_XXXXXX',
			DIR    => $temp_dir,
			UNLINK => 0,
			PERMS  => 0644,
		);
	};
	unless ($fh) {
		return {
			status => 'error',
			error  => "could not create cookie file in $temp_dir: " . ( $@ || $! ),
		};
	}
	print {$fh} $cookie;
	close $fh;

	my $verdict = $self->call(
		command => 'auth_verify',
		args    => { path => $cookie_path },
		( defined $timeout ? ( timeout => $timeout ) : () ),
	);
	unlink $cookie_path;    # server unlinks it; clean up if it did not

	if ( ( $verdict->{status} // '' ) eq 'ok' ) {
		$self->{auth} = {
			uid      => $verdict->{result}{uid},
			username => $verdict->{result}{username},
			groups   => $verdict->{result}{groups} // [],
		};
	}
	return $verdict;
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

sub connected     { return defined $_[0]{socket} }
sub authenticated { return defined $_[0]{auth} }
sub uid           { return $_[0]{auth} ? $_[0]{auth}{uid} : undef }
sub username      { return $_[0]{auth} ? $_[0]{auth}{username} : undef }
sub groups        { return $_[0]{auth} ? $_[0]{auth}{groups} : undef }

sub DESTROY {
	my ($self) = @_;
	close delete $self->{socket} if $self->{socket};
	return;
}

1;

__END__

=pod

=head1 CAVEATS

One request is on the wire at a time; there is no pipelining and no
out-of-order correlation beyond skipping messages that do not match the
awaited C<id>. Unsolicited messages pushed by server-side handlers are only
noticed (and handed to C<on_notice>) while a C<call> is waiting for its
response -- a blocking client has no way to listen between calls.

=head1 SEE ALSO

L<POE::Component::Server::JSONUnix>,
L<POE::Component::Server::JSONUnix::Client>, L<IO::Socket::UNIX>,
L<JSON::MaybeXS>.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
