package POE::Component::Server::JSONUnix;

use strict;
use warnings;
use v5.10;
use mro;

use Carp             qw(carp croak);
use Socket           qw(PF_UNIX SOCK_STREAM);
use IO::Socket::UNIX ();
use JSON::MaybeXS    ();

use POE qw(
	Wheel::SocketFactory
	Wheel::ReadWrite
	Filter::Line
	Driver::SysRW
);

our $VERSION = '0.0.1';

=head1 NAME

POE::Component::Server::JSONUnix - pluggable JSON-over-Unix-socket server for POE

=head1 SYNOPSIS

    use POE;
    use POE::Component::Server::JSONUnix;

    my $server = POE::Component::Server::JSONUnix->spawn(
        socket_path => '/tmp/app.sock',
        socket_mode => 0600,
        commands    => {
            echo => sub {
                my ($server, $request, $ctx) = @_;
                return { echoed => $request->{args} };
            },
        },
    );

    # Add more commands at any time.
    $server->register(
        add => sub {
            my ($server, $request, $ctx) = @_;
            my $sum = 0;
            $sum += $_ for @{ $request->{args}{numbers} // [] };
            return { sum => $sum };
        },
    );

    $poe_kernel->run;

=head1 DESCRIPTION

This module is a small, event-driven server that listens on a Unix domain
socket and speaks a simple JSON request/response protocol. It is built on
L<POE> and is designed to be extended: the set of commands it understands is a
plain dispatch table you can add to at construction time, at run time, or by
subclassing.

It is suitable as a local control or RPC endpoint for a daemon -- the sort of
thing you talk to from a command-line tool, a cron job, or another process on
the same host.

=head1 PROTOCOL

The framing is newline-delimited JSON: each message is a single JSON object on
its own line, terminated by C<\n>. (Pretty-printed, multi-line JSON is not
supported by the default filter; see L</"Changing the framing">.)

A request looks like:

    {"command":"add","args":{"numbers":[1,2,3]},"id":7}

=over 4

=item *

C<command> (required) -- the name of the command to run. C<cmd> is accepted as
an alias.

=item *

C<args> (optional) -- an arbitrary payload passed straight through to the
handler.

=item *

C<id> (optional) -- an opaque value echoed back in the response so asynchronous
clients can correlate replies with requests.

=back

A successful response:

    {"id":7,"status":"ok","result":{"sum":6}}

An error response:

    {"id":7,"status":"error","error":"unknown command: subtract"}

Malformed JSON, a non-object request, a missing command, an unknown command, or
a handler that dies all produce an C<error> response rather than disturbing the
server or other clients.

=head1 CONSTRUCTOR

=head2 spawn

    my $server = POE::Component::Server::JSONUnix->spawn(%args);

Creates the server's POE session and returns the server object. Recognised
arguments:

=over 4

=item *

C<socket_path> (required) -- filesystem path of the Unix domain socket to listen
on. If a stale socket file is present it is removed; if another process is
actively listening there, C<spawn> dies rather than clobber it.

=item *

C<commands> -- hash reference of C<< name => \&handler >> pairs to register. See
L</"COMMAND HANDLERS">.

=item *

C<socket_mode> -- if set (e.g. C<0600>), C<chmod> the socket to these
permissions after binding. Unix socket permissions govern who may connect, so
setting this is recommended.

=item *

C<alias> -- POE session alias. Defaults to C<json_unix_server>. Set this if you
run more than one server in a single process.

=item *

C<unlink_existing> -- whether to remove a stale (not-in-use) socket file on
startup. Defaults to true.

=item *

C<on_error> -- code reference called as
C<< $cb->($operation, $errnum, $errstr [, $wheel_id]) >> on listen and
connection I/O errors. Normal client disconnects are not reported.

=back

=cut

sub spawn {
	my ( $class, %args ) = @_;

	my $path = delete $args{socket_path}
		or croak "spawn() requires a 'socket_path' argument";

	my $self = bless {
		socket_path     => $path,
		alias           => ( delete $args{alias} ) // 'json_unix_server',
		socket_mode     => delete $args{socket_mode},                       # e.g. 0600
		unlink_existing => ( delete $args{unlink_existing} ) // 1,
		on_error        => delete $args{on_error},                          # coderef (optional)
		commands        => {},
		clients         => {},
		json            => JSON::MaybeXS->new(
			utf8         => 1,
			canonical    => 1,
			allow_nonref => 0,
		),
	}, $class;

	# Precedence (later overrides earlier): built-ins < cmd_* methods < arg.
	$self->_register_builtins;
	$self->_register_cmd_methods;

	if ( defined( my $cmds = delete $args{commands} ) ) {
		croak "'commands' must be a hash reference"
			unless ref $cmds eq 'HASH';
		$self->register(%$cmds);
	}

	# Fail fast and synchronously on a busy or unusable socket path, so the
	# caller of spawn() gets the error rather than a dead session later.
	$self->_prepare_socket_path;

	POE::Session->create(
		object_states => [
			$self => {
				_start           => '_poe_start',
				_stop            => '_poe_stop',
				shutdown         => '_poe_shutdown',
				register_command => '_poe_register_command',
				got_connection   => '_poe_got_connection',
				listen_error     => '_poe_listen_error',
				client_input     => '_poe_client_input',
				client_error     => '_poe_client_error',
				client_flushed   => '_poe_client_flushed',
			},
		],
	);

	return $self;
} ## end sub spawn

#--- command registration --------------------------------------------------

=head1 METHODS

=head2 register

    $server->register(name => \&handler, ...);

Add or replace commands. Returns the server object. Croaks if a handler is not a
code reference.

=cut

# register(name => \&handler, ...) — add or replace commands at any time.
sub register {
	my ( $self, %cmds ) = @_;
	for my $name ( sort keys %cmds ) {
		my $code = $cmds{$name};
		croak "Handler for command '$name' must be a code reference"
			unless ref $code eq 'CODE';
		$self->{commands}{$name} = $code;
	}
	return $self;
} ## end sub register

=head2 command_names

    my $names = $server->command_names;   # array reference, sorted

The names of all currently registered commands. (Also available to clients as
the built-in C<commands> command.)

=cut

sub command_names { return [ sort keys %{ $_[0]->{commands} } ] }

sub _register_builtins {
	my ($self) = @_;
	$self->register(
		ping => sub {
			my ( $server, $req, $ctx ) = @_;
			return { pong => 1, time => time() };
		},
		commands => sub {
			my ( $server, $req, $ctx ) = @_;
			return { commands => $server->command_names };
		},
	);
	return;
} ## end sub _register_builtins

# Discover cmd_<name> methods anywhere in the class hierarchy so a server can
# be built simply by subclassing this module and adding methods.
sub _register_cmd_methods {
	my ($self) = @_;
	my %names;
	no strict 'refs';
	for my $pkg ( @{ mro::get_linear_isa( ref $self ) } ) {
		for my $sym ( keys %{"${pkg}::"} ) {
			$names{$1} = 1 if $sym =~ /\Acmd_(.+)\z/;
		}
	}
	for my $name ( keys %names ) {
		my $method = "cmd_$name";
		next unless $self->can($method);
		$self->{commands}{$name} = sub {
			my ( $server, $req, $ctx ) = @_;
			return $server->$method( $req, $ctx );
		};
	}
	return;
} ## end sub _register_cmd_methods

=head2 shutdown

    $server->shutdown;

Stop accepting connections, close all clients, remove the socket file, and let
the session end.

=cut

sub shutdown {
	my ($self) = @_;
	$poe_kernel->post( $self->{alias}, 'shutdown' );
	return;
}

#--- socket setup ----------------------------------------------------------

sub _prepare_socket_path {
	my ($self) = @_;
	my $path = $self->{socket_path};

	return unless -e $path;

	croak "socket_path '$path' exists and is not a socket"
		unless -S $path;

	# If something is actively listening there, refuse rather than clobber it.
	my $probe = IO::Socket::UNIX->new( Type => SOCK_STREAM, Peer => $path );
	if ($probe) {
		close $probe;
		croak "Another server is already listening on '$path'";
	}

	croak "Stale socket '$path' present but unlink_existing is disabled"
		unless $self->{unlink_existing};

	unlink $path
		or croak "Could not remove stale socket '$path': $!";
	return;
} ## end sub _prepare_socket_path

#--- POE: session lifecycle ------------------------------------------------

sub _poe_start {
	my ( $self, $kernel ) = @_[ OBJECT, KERNEL ];

	$kernel->alias_set( $self->{alias} );

	$self->{listener} = POE::Wheel::SocketFactory->new(
		SocketDomain => PF_UNIX,
		SocketType   => SOCK_STREAM,
		BindAddress  => $self->{socket_path},
		SuccessEvent => 'got_connection',
		FailureEvent => 'listen_error',
	);

	if ( defined $self->{socket_mode} ) {
		chmod $self->{socket_mode}, $self->{socket_path}
			or carp "chmod on '$self->{socket_path}' failed: $!";
	}
	return;
} ## end sub _poe_start

sub _poe_stop {
	my ($self) = $_[OBJECT];
	$self->_remove_socket_file;
	return;
}

sub _poe_shutdown {
	my ( $self, $kernel ) = @_[ OBJECT, KERNEL ];
	delete $self->{listener};      # stop accepting new connections
	%{ $self->{clients} } = ();    # drop wheels -> close client sockets
	$kernel->alias_remove( $self->{alias} );
	$self->_remove_socket_file;
	return;
}

sub _poe_register_command {
	my ( $self, $name, $code ) = @_[ OBJECT, ARG0, ARG1 ];
	eval { $self->register( $name => $code ) };
	carp "register_command failed: $@" if $@;
	return;
}

sub _remove_socket_file {
	my ($self) = @_;
	my $path = $self->{socket_path};
	unlink $path if defined $path && -S $path;
	return;
}

#--- POE: listener events --------------------------------------------------

sub _poe_listen_error {
	my ( $self, $op, $errnum, $errstr ) = @_[ OBJECT, ARG0, ARG1, ARG2 ];
	carp "listen error during $op: $errstr ($errnum)";
	$self->{on_error}->( "listen:$op", $errnum, $errstr ) if $self->{on_error};
	delete $self->{listener};
	return;
}

sub _poe_got_connection {
	my ( $self, $socket ) = @_[ OBJECT, ARG0 ];

	my $wheel = POE::Wheel::ReadWrite->new(
		Handle       => $socket,
		Driver       => POE::Driver::SysRW->new,
		Filter       => POE::Filter::Line->new( Literal => "\n" ),
		InputEvent   => 'client_input',
		ErrorEvent   => 'client_error',
		FlushedEvent => 'client_flushed',
	);

	$self->{clients}{ $wheel->ID } = {
		wheel             => $wheel,
		close_after_flush => 0,
	};
	return;
} ## end sub _poe_got_connection

#--- POE: per-client events ------------------------------------------------

sub _poe_client_input {
	my ( $self, $line, $id ) = @_[ OBJECT, ARG0, ARG1 ];

	return unless $self->{clients}{$id};
	return unless defined $line && $line =~ /\S/;    # ignore blank keepalives

	my $request;
	unless ( eval { $request = $self->{json}->decode($line); 1 } ) {
		$self->_send(
			$id,
			{
				status => 'error',
				error  => 'invalid JSON: ' . _clean_err($@),
			}
		);
		return;
	} ## end unless ( eval { $request = $self->{json}->decode...})

	unless ( ref $request eq 'HASH' ) {
		$self->_send(
			$id,
			{
				status => 'error',
				error  => 'request must be a JSON object',
			}
		);
		return;
	} ## end unless ( ref $request eq 'HASH' )

	my $req_id   = $request->{id};
	my $cmd_name = $request->{command} // $request->{cmd};

	my $ctx = POE::Component::Server::JSONUnix::Context->_new(
		server   => $self,
		wheel_id => $id,
		req_id   => $req_id,
		command  => $cmd_name,
		request  => $request,
	);

	unless ( defined $cmd_name ) {
		$ctx->error("missing 'command' field");
		return;
	}

	my $handler = $self->{commands}{$cmd_name};
	unless ($handler) {
		$ctx->error("unknown command: $cmd_name");
		return;
	}

	my @ret = eval { $handler->( $self, $request, $ctx ) };
	if ( my $err = $@ ) {
		unless ( $ctx->responded ) {
			if ( ref $err eq 'HASH' ) {
				$ctx->respond( { status => 'error', %$err } );
			} else {
				$ctx->error( _clean_err($err) );
			}
		}
		return;
	} ## end if ( my $err = $@ )

	return if $ctx->responded;          # handler already answered (any path)
	return unless defined $ret[0];      # undef return => async; answers later
	$ctx->respond_result( $ret[0] );    # sync return => wrap as {ok, result}
	return;
} ## end sub _poe_client_input

sub _poe_client_error {
	my ( $self, $op, $errnum, $errstr, $id ) = @_[ OBJECT, ARG0, ARG1, ARG2, ARG3 ];

	# operation 'read' with errnum 0 is a normal EOF (client hung up).
	if ( $self->{on_error} && !( $op eq 'read' && $errnum == 0 ) ) {
		eval { $self->{on_error}->( $op, $errnum, $errstr, $id ) };
	}
	$self->_close_client($id);
	return;
} ## end sub _poe_client_error

sub _poe_client_flushed {
	my ( $self, $id ) = @_[ OBJECT, ARG0 ];
	my $client = $self->{clients}{$id} or return;
	$self->_close_client($id) if $client->{close_after_flush};
	return;
}

#--- sending / closing -----------------------------------------------------

sub _send {
	my ( $self, $id, $data ) = @_;
	my $client = $self->{clients}{$id} or return;
	my $wheel  = $client->{wheel}      or return;

	my $json = eval { $self->{json}->encode($data) };
	unless ( defined $json ) {
		$json = $self->{json}->encode(
			{
				status => 'error',
				error  => 'internal error: response could not be serialised',
			}
		);
	}
	$wheel->put($json);    # Filter::Line appends the trailing newline
	return;
} ## end sub _send

sub _close_client {
	my ( $self, $id ) = @_;
	delete $self->{clients}{$id};    # destroying the wheel closes the socket
	return;
}

sub _close_client_after_flush {
	my ( $self, $id ) = @_;
	my $client = $self->{clients}{$id} or return;
	my $wheel  = $client->{wheel};
	if ( $wheel && $wheel->get_driver_out_octets ) {
		$client->{close_after_flush} = 1;
	} else {
		$self->_close_client($id);
	}
	return;
} ## end sub _close_client_after_flush

sub _clean_err {
	my ($msg) = @_;
	$msg = "$msg";
	$msg =~ s/\s+at \S+ line \d+\.?.*//s;    # strip "at file line N ..."
	$msg =~ s/\s+\z//;
	return $msg;
}

#===========================================================================
package POE::Component::Server::JSONUnix::Context;
#===========================================================================
# Handed to every command handler. A handler can answer synchronously by
# returning a value, or asynchronously by stashing $ctx and calling one of
# these methods later (e.g. after a timer fires or a backend request returns).

our $VERSION = '0.01';

sub _new {
	my ( $class, %a ) = @_;
	return bless {
		server    => $a{server},
		wheel_id  => $a{wheel_id},
		req_id    => $a{req_id},
		command   => $a{command},
		request   => $a{request},
		responded => 0,
	}, $class;
} ## end sub _new

sub request   { $_[0]{request} }
sub command   { $_[0]{command} }
sub id        { $_[0]{req_id} }
sub responded { $_[0]{responded} }

# Send a full response envelope. status defaults to 'ok'; the request id, if
# present, is echoed back automatically. Only the first call has any effect.
sub respond {
	my ( $self, $envelope ) = @_;
	return if $self->{responded};
	$self->{responded} = 1;

	my %out = %$envelope;
	$out{status} //= 'ok';
	$out{id} = $self->{req_id}
		if defined $self->{req_id} && !exists $out{id};

	$self->{server}->_send( $self->{wheel_id}, \%out );
	return;
} ## end sub respond

# Convenience: respond with {status:ok, result:<data>}.
sub respond_result {
	my ( $self, $result ) = @_;
	return $self->respond( { status => 'ok', result => $result } );
}

# Convenience: respond with {status:error, error:<message>, ...extra}.
sub error {
	my ( $self, $message, %extra ) = @_;
	return $self->respond( { status => 'error', error => $message, %extra } );
}

# Close this client's connection once any queued output has been flushed.
sub close {
	my ($self) = @_;
	$self->{server}->_close_client_after_flush( $self->{wheel_id} );
	return;
}

1;

__END__

=pod

=head1 COMMAND HANDLERS

A handler is a code reference called as:

    $handler->($server, $request, $ctx)

where C<$request> is the decoded request hash and C<$ctx> is a context object
(see L</"THE CONTEXT OBJECT">). A handler answers in one of three ways:

=over 4

=item Synchronously

Return a value. It is wrapped and sent as
C<< {status => 'ok', result => $value} >>.

=item By raising an error

C<die> with a string (sent as C<< {status => 'error', error => $string} >>, with
the trailing "at FILE line N" trimmed) or with a hash reference (merged into the
error response).

=item Asynchronously

Return C<undef>, stash C<$ctx> somewhere, and call
C<< $ctx->respond_result(...) >> (or C<< $ctx->error(...) >>) later -- for
example after a timer fires or a backend request completes.

=back

=head1 ADDING COMMANDS

Commands can be registered three ways. When names collide, later wins, in this
order: built-ins, then C<cmd_*> methods, then the C<commands> argument and
C<register>.

=head2 1. At construction

    POE::Component::Server::JSONUnix->spawn(
        socket_path => $path,
        commands    => { hello => sub { ... } },
    );

=head2 2. With register

    $server->register(name => sub { ... }, name2 => sub { ... });

From inside another POE session you can instead post to the server's alias:

    $poe_kernel->post($alias => register_command => $name => \&handler);

=head2 3. By subclassing

Any method named C<cmd_E<lt>nameE<gt>> anywhere in the class hierarchy is
discovered automatically and exposed as a command. It is invoked as
C<< $server->cmd_name($request, $ctx) >>.

    package MyApp::Server;
    use parent 'POE::Component::Server::JSONUnix';

    sub cmd_whoami { my ($self, $req, $ctx) = @_; return { user => $ENV{USER} } }
    sub cmd_uptime { my ($self, $req, $ctx) = @_; return { up => time() - $^T } }

    MyApp::Server->spawn(socket_path => '/tmp/app.sock');

=head1 THE CONTEXT OBJECT

Each handler receives a context object (an instance of
C<POE::Component::Server::JSONUnix::Context>) as its third argument. It carries
the request and provides the reply methods, which is what makes asynchronous
handlers possible: keep the object alive past the handler's return and answer
when ready.

=over 4

=item C<< $ctx->respond_result($data) >>

Send C<< {status => 'ok', result => $data} >>.

=item C<< $ctx->error($message, %extra) >>

Send C<< {status => 'error', error => $message, %extra} >>.

=item C<< $ctx->respond(\%envelope) >>

Send a raw response envelope. C<status> defaults to C<ok> and the request C<id>
is added automatically. Only the first reply on a context has any effect.

=item C<< $ctx->request >>, C<< $ctx->id >>, C<< $ctx->command >>

Accessors for the decoded request, its C<id>, and the command name.

=item C<< $ctx->close >>

Close this client's connection once any queued output has been flushed.

=back

=head1 BUILT-IN COMMANDS

=over 4

=item C<ping>

Returns C<< {pong => 1, time => <epoch>} >>.

=item C<commands>

Returns C<< {commands => [ ...names... ]} >> -- handy for discovery.

=back

=head1 Changing the framing

The default filter is L<POE::Filter::Line>, giving one-object-per-line framing.
If you would rather frame on complete JSON values (allowing pretty-printed
input), replace the filter in the connection setup with L<POE::Filter::JSON>.

=head1 DEPENDENCIES

L<POE> and L<JSON::MaybeXS>. Installing L<Cpanel::JSON::XS> or L<JSON::XS> lets
JSON::MaybeXS pick a fast XS backend automatically.

=head1 SEE ALSO

L<POE>, L<POE::Wheel::SocketFactory>, L<POE::Wheel::ReadWrite>,
L<POE::Filter::Line>, L<JSON::MaybeXS>.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
