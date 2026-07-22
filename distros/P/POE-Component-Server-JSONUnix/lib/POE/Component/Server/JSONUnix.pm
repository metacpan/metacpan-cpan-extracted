package POE::Component::Server::JSONUnix;

use strict;
use warnings;
use v5.10;
use mro;

use Carp             qw(carp croak);
use File::Basename   ();
use File::Spec       ();
use Socket           qw(PF_UNIX SOCK_STREAM);
use IO::Socket::UNIX ();
use JSON::MaybeXS    ();

use POE qw(
	Wheel::SocketFactory
	Wheel::ReadWrite
	Filter::Line
	Driver::SysRW
);

our $VERSION = '0.1.0';

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
its own line, terminated by C<\n>.

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

=head3 socket_path

Required. Filesystem path of the Unix domain socket to listen on. If a stale
socket file is present it is removed; if another process is actively
listening there, C<spawn> dies rather than clobber it.

=head3 commands

Hash reference of C<< name => \&handler >> pairs to register. See
L</"COMMAND HANDLERS">.

=head3 socket_mode

If set (e.g. C<0600>), C<chmod> the socket to these permissions after
binding. Unix socket permissions govern who may connect, so setting this is
recommended.

=head3 alias

POE session alias. Defaults to C<json_unix_server>. Set this if you run more
than one server in a single process.

=head3 unlink_existing

Whether to remove a stale (not-in-use) socket file on startup. Defaults to
true.

=head3 on_error

Code reference called as
C<< $cb->($operation, $errnum, $errstr [, $wheel_id]) >> on listen and
connection I/O errors. Normal client disconnects are not reported.

=head3 auth_temp_dir

Directory used for the cookie-file ownership challenge. Defaults to
C<File::Spec-E<gt>tmpdir> (usually C</tmp>).

=head3 auth_required

If set to a true value, all commands except C<auth_start> and C<auth_verify>
return an error until the client has successfully completed the ownership
challenge. Defaults to false.

=head3 permissions

Optional user/group permission policy, a hash reference of the form
C<< {default => 'allow'|'deny', commands => {name => $spec, ...}} >>. When
this argument is not given the server behaves exactly as it does without the
feature. See L</"PERMISSIONS">.

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
		auth_temp_dir   => ( delete $args{auth_temp_dir} ) // File::Spec->tmpdir,
		auth_required   => ( delete $args{auth_required} ) // 0,
		permissions     => undef,                                            # stays undef unless a policy is passed to spawn
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

	# Optional user/group permission policy. Validated here so a bad policy
	# fails spawn() synchronously; when the argument is absent the server
	# behaves exactly as it did without the feature.
	if ( defined( my $perms = delete $args{permissions} ) ) {
		$self->{permissions} = _build_permissions($perms);
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
			my $names = $server->command_names;
			$names = [ grep { $ctx->may($_) } @$names ]
				if $server->{permissions};
			return { commands => $names };
		},
	);
	$self->_register_auth_builtins;
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

sub _register_auth_builtins {
	my ($self) = @_;

	$self->register(
		auth_start => sub {
			my ( $server, $req, $ctx ) = @_;
			my $id     = $ctx->{wheel_id};
			my $client = $server->{clients}{$id};
			my $cookie = _random_cookie();
			$client->{auth_cookie} = $cookie;
			$client->{auth_time}   = time();
			return {
				cookie   => $cookie,
				temp_dir => $server->{auth_temp_dir},
			};
		},

		auth_verify => sub {
			my ( $server, $req, $ctx ) = @_;
			my $id     = $ctx->{wheel_id};
			my $client = $server->{clients}{$id};

			unless ( defined $client->{auth_cookie} ) {
				$ctx->error('no pending auth challenge: call auth_start first');
				return;
			}

			my $path = $req->{args}{path} // '';
			unless ( $path && File::Spec->file_name_is_absolute($path) ) {
				$ctx->error('args.path must be an absolute file path');
				return;
			}

			# Must be directly inside auth_temp_dir — no subdirectories.
			my $temp_dir = $server->{auth_temp_dir};
			my $dirname  = File::Basename::dirname($path);
			unless ( $dirname eq $temp_dir ) {
				$ctx->error("path must be a file directly inside $temp_dir");
				return;
			}

			# lstat so we never follow symlinks.
			my @st = lstat($path);
			unless (@st) {
				delete $client->{auth_cookie};
				$ctx->error('verification file not found');
				return;
			}

			if ( -l _ ) {
				unlink $path;
				delete $client->{auth_cookie};
				$ctx->error('verification file must not be a symbolic link');
				return;
			}

			unless ( -f _ ) {
				delete $client->{auth_cookie};
				$ctx->error('verification file must be a regular file');
				return;
			}

			# Read the file contents (limit to avoid reading huge files).
			my $content = '';
			if ( open( my $fh, '<:raw', $path ) ) {
				read( $fh, $content, 256 );
				close($fh);
			}
			unlink($path);    # clean up regardless of outcome
			$content =~ s/\s+\z//;    # strip trailing whitespace the client may have added

			my $expected = $client->{auth_cookie};
			delete $client->{auth_cookie};
			delete $client->{auth_time};

			unless ( $content eq $expected ) {
				$ctx->error('cookie mismatch: verification failed');
				return;
			}

			my $uid      = $st[4];
			my $username = ( getpwuid($uid) )[0] // '';

			$client->{auth_uid}      = $uid;
			$client->{auth_username} = $username;

			# With a permission policy in force, resolve and cache the user's
			# groups now so the first gated request does not pay for it, and
			# report them back. Without one, the response is exactly what it
			# always was.
			if ( $server->{permissions} ) {
				my $groups = $server->_client_groups( $ctx->{wheel_id} );
				return {
					uid      => $uid + 0,
					username => $username,
					groups   => $groups ? $groups->{list} : [],
				};
			}

			return { uid => $uid + 0, username => $username };
		},
	);
	return;
} ## end sub _register_auth_builtins

#--- permissions -------------------------------------------------------------

# Validate and normalise the 'permissions' spawn argument into the internal
# form used by _permission_verdict.
sub _build_permissions {
	my ($perms) = @_;

	croak "'permissions' must be a hash reference"
		unless ref $perms eq 'HASH';

	my %in  = %$perms;
	my %out = ( default => 'allow', commands => {} );

	if ( defined( my $default = delete $in{default} ) ) {
		croak "permissions 'default' must be 'allow' or 'deny'"
			unless $default eq 'allow' || $default eq 'deny';
		$out{default} = $default;
	}

	if ( defined( my $cmds = delete $in{commands} ) ) {
		croak "permissions 'commands' must be a hash reference"
			unless ref $cmds eq 'HASH';
		for my $name ( sort keys %$cmds ) {
			$out{commands}{$name} = _normalize_permission_spec( $name, $cmds->{$name} );
		}
	}

	croak "unknown permissions key(s): " . join( ', ', sort keys %in )
		if %in;

	return \%out;
} ## end sub _build_permissions

# A spec is 'allow', 'deny', or a hash of rule lists. Entries that look like
# a number are treated as uids/gids; everything else as user/group names.
# Lists are turned into lookup hashes once, here, so per-request checks are
# cheap.
sub _normalize_permission_spec {
	my ( $name, $spec ) = @_;

	unless ( ref $spec ) {
		croak "permission for '$name' must be 'allow', 'deny', or a hash reference"
			unless defined $spec && ( $spec eq 'allow' || $spec eq 'deny' );
		return $spec;
	}
	croak "permission for '$name' must be 'allow', 'deny', or a hash reference"
		unless ref $spec eq 'HASH';

	my %in = %$spec;
	my %norm;

	for my $key (qw(users deny_users)) {
		next unless defined( my $list = delete $in{$key} );
		croak "'$key' for '$name' must be an array reference"
			unless ref $list eq 'ARRAY';
		for my $entry (@$list) {
			if   ( $entry =~ /\A[0-9]+\z/ ) { $norm{$key}{uids}{$entry}  = 1 }
			else                            { $norm{$key}{names}{$entry} = 1 }
		}
	}

	for my $key (qw(groups deny_groups)) {
		next unless defined( my $list = delete $in{$key} );
		croak "'$key' for '$name' must be an array reference"
			unless ref $list eq 'ARRAY';
		for my $entry (@$list) {
			if   ( $entry =~ /\A[0-9]+\z/ ) { $norm{$key}{gids}{$entry}  = 1 }
			else                            { $norm{$key}{names}{$entry} = 1 }
		}
	}

	if ( defined( my $check = delete $in{check} ) ) {
		croak "'check' for '$name' must be a code reference"
			unless ref $check eq 'CODE';
		$norm{check} = $check;
	}

	croak "unknown permission key(s) for '$name': " . join( ', ', sort keys %in )
		if %in;

	return \%norm;
} ## end sub _normalize_permission_spec

# Full group membership for a user, via the same getpw*/getgr* calls perl
# provides everywhere: they route through the platform's NSS (or its local
# equivalent), so files, LDAP, sssd, and friends all just work. Includes the
# primary group from the passwd entry and every secondary group whose member
# list names the user.
sub _resolve_user_groups {
	my ( $uid, $username ) = @_;

	my %names;
	my %gids;

	eval {
		my @pw = getpwuid($uid);
		if (@pw) {
			my $primary_gid = $pw[3];
			$gids{$primary_gid} = 1;
			my $primary_name = getgrgid($primary_gid);
			$names{$primary_name} = 1 if defined $primary_name;
		}

		if ( defined $username && length $username ) {
			setgrent();
			while ( my @gr = getgrent() ) {
				my ( $group_name, $gid, $members ) = @gr[ 0, 2, 3 ];
				next
					unless defined $members
					&& grep { $_ eq $username } split ' ', $members;
				$gids{$gid} = 1;
				$names{$group_name} = 1 if defined $group_name;
			}
			endgrent();
		} ## end if ( defined $username && length $username)
	};

	return {
		names => \%names,
		gids  => \%gids,
		list  => [ sort keys %names ],
	};
} ## end sub _resolve_user_groups

# Group info for an authenticated connection, resolved at most once per
# connection and cached on the client record -- group database lookups can be
# expensive (LDAP, NIS, ...) and must not be paid per request.
sub _client_groups {
	my ( $self, $id ) = @_;
	my $client = $self->{clients}{$id} or return undef;
	return undef unless defined $client->{auth_uid};
	$client->{auth_group_info} //= _resolve_user_groups( $client->{auth_uid}, $client->{auth_username} );
	return $client->{auth_group_info};
}

# Decide whether the client behind wheel $id may run $cmd_name under the
# configured policy. Returns 1 to allow, or (0, $code, $message) to deny.
# Only called when a policy is configured.
sub _permission_verdict {
	my ( $self, $id, $cmd_name, $ctx ) = @_;

	# The handshake itself must always be reachable, or nobody could ever
	# gain the identity the policy is written in terms of.
	return 1 if $cmd_name eq 'auth_start' || $cmd_name eq 'auth_verify';

	# A command's own rule wins; the special '%DEFAULT%' entry covers any
	# command (known or not) without one; the 'default' string is last.
	my $perms = $self->{permissions};
	my $spec =
		$perms->{commands}{$cmd_name}
		// $perms->{commands}{'%DEFAULT%'}
		// $perms->{default};

	unless ( ref $spec ) {
		return 1 if $spec eq 'allow';
		return ( 0, 'permission_denied', "permission denied: $cmd_name" );
	}

	my $client = $self->{clients}{$id}
		or return ( 0, 'permission_denied', "permission denied: $cmd_name" );

	# A rule written in terms of users or groups implies the connection must
	# be authenticated, even when auth_required is off globally.
	unless ( defined $client->{auth_uid} ) {
		return ( 0, 'auth_required', 'authentication required: call auth_start then auth_verify first' );
	}

	my $uid      = $client->{auth_uid};
	my $username = $client->{auth_username} // '';
	my $groups   = $self->_client_groups($id);
	my $denial   = "permission denied: user '$username' may not run '$cmd_name'";

	# Explicit denies win over everything.
	if ( my $deny = $spec->{deny_users} ) {
		return ( 0, 'permission_denied', $denial )
			if $deny->{names}{$username} || $deny->{uids}{$uid};
	}
	if ( my $deny = $spec->{deny_groups} ) {
		for my $group_name ( keys %{ $groups->{names} } ) {
			return ( 0, 'permission_denied', $denial ) if $deny->{names}{$group_name};
		}
		for my $gid ( keys %{ $groups->{gids} } ) {
			return ( 0, 'permission_denied', $denial ) if $deny->{gids}{$gid};
		}
	}

	# With no allow criteria at all (a deny-list-only spec, or an empty
	# hash), whoever survived the denies falls through to the default.
	unless ( $spec->{users} || $spec->{groups} || $spec->{check} ) {
		return 1 if $perms->{default} eq 'allow';
		return ( 0, 'permission_denied', $denial );
	}

	# Any matching allow criterion is enough.
	if ( my $allow = $spec->{users} ) {
		return 1 if $allow->{names}{$username} || $allow->{uids}{$uid};
	}
	if ( my $allow = $spec->{groups} ) {
		for my $group_name ( keys %{ $groups->{names} } ) {
			return 1 if $allow->{names}{$group_name};
		}
		for my $gid ( keys %{ $groups->{gids} } ) {
			return 1 if $allow->{gids}{$gid};
		}
	}
	if ( my $check = $spec->{check} ) {
		my $ok = eval { $check->( $self, $ctx, $cmd_name ) };
		if ($@) {
			carp "permission check for '$cmd_name' died: $@";    # fail closed
		} elsif ($ok) {
			return 1;
		}
	}

	return ( 0, 'permission_denied', $denial );
} ## end sub _permission_verdict

sub _random_cookie {
	my $bytes = '';
	if ( open( my $fh, '<:raw', '/dev/urandom' ) ) {
		read( $fh, $bytes, 16 );
		close($fh);
	}
	# Fallback: should never happen on a Unix system.
	unless ( length($bytes) == 16 ) {
		$bytes = pack( 'N4', map { int( rand(2**32) ) } 1 .. 4 );
	}
	return unpack( 'H*', $bytes );    # 32 lowercase hex chars
}

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
		auth_cookie       => undef,
		auth_uid          => undef,
		auth_username     => undef,
		auth_group_info   => undef,    # filled once by _client_groups
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

	# Enforce auth_required: only auth_start and auth_verify bypass the gate.
	if ( $self->{auth_required} && !defined( $self->{clients}{$id}{auth_uid} ) ) {
		unless ( $cmd_name eq 'auth_start' || $cmd_name eq 'auth_verify' ) {
			$ctx->error('authentication required: call auth_start then auth_verify first');
			return;
		}
	}

	# Enforce the optional permission policy. Runs before the unknown-command
	# check so a default-deny server does not reveal which commands exist.
	if ( $self->{permissions} ) {
		my ( $allowed, $code, $denial ) = $self->_permission_verdict( $id, $cmd_name, $ctx );
		unless ($allowed) {
			$ctx->error( $denial, code => $code );
			return;
		}
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

# Auth accessors — defined after a successful auth_verify.
sub authenticated {
	my ($self) = @_;
	return defined $self->{server}{clients}{ $self->{wheel_id} }{auth_uid};
}

sub uid {
	my ($self) = @_;
	return $self->{server}{clients}{ $self->{wheel_id} }{auth_uid};
}

sub username {
	my ($self) = @_;
	return $self->{server}{clients}{ $self->{wheel_id} }{auth_username};
}

# Group names of the authenticated user (empty before authentication).
# Resolved via NSS at most once per connection, then served from the cache.
sub groups {
	my ($self) = @_;
	my $groups = $self->{server}->_client_groups( $self->{wheel_id} );
	return $groups ? [ @{ $groups->{list} } ] : [];
}

# Membership test by group name or numeric gid.
sub in_group {
	my ( $self, $group ) = @_;
	return 0 unless defined $group;
	my $groups = $self->{server}->_client_groups( $self->{wheel_id} )
		or return 0;
	my $set = $group =~ /\A[0-9]+\z/ ? $groups->{gids} : $groups->{names};
	return $set->{$group} ? 1 : 0;
}

# Would this connection be allowed to run $command_name right now? Always
# true when no permission policy is configured.
sub may {
	my ( $self, $command_name ) = @_;
	return 1 unless $self->{server}{permissions};
	my ($allowed) = $self->{server}->_permission_verdict( $self->{wheel_id}, $command_name, $self );
	return $allowed ? 1 : 0;
}

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

=item C<< $ctx->authenticated >>

True if this client has completed a successful C<auth_verify> exchange.

=item C<< $ctx->uid >>

The numeric UID of the authenticated user, or C<undef> if not yet verified.

=item C<< $ctx->username >>

The username corresponding to C<< $ctx->uid >>, or C<undef> if not yet
verified.

=item C<< $ctx->groups >>

Array reference of the authenticated user's group names (primary and
secondary), or an empty array reference before verification. Resolved via
NSS at most once per connection and cached; see L</"PERMISSIONS">.

=item C<< $ctx->in_group($group) >>

True if the authenticated user belongs to the given group, by name or by
numeric GID. False before verification.

=item C<< $ctx->may($command_name) >>

True if this connection would currently be allowed to run the named command.
Always true when no permission policy is configured. Useful for finer-grained
decisions inside a handler than the per-command rules can express.

=back

=head1 BUILT-IN COMMANDS

=over 4

=item C<ping>

Returns C<< {pong => 1, time => <epoch>} >>.

=item C<commands>

Returns C<< {commands => [ ...names... ]} >> -- handy for discovery. When a
permission policy is configured, only the commands the caller may currently
run are listed.

=item C<auth_start>

Begins the Unix-ownership challenge. Returns
C<< {cookie => "<hex>", temp_dir => "<dir>"} >>. The client must write the
cookie string to a new regular file inside C<temp_dir> and then call
C<auth_verify>.

=item C<auth_verify>

Completes the challenge. C<args> must contain C<path>: the absolute path of the
file the client wrote in C<temp_dir>. The server:

=over 4

=item 1. Confirms the path is a regular (non-symlink) file directly inside C<auth_temp_dir>.

=item 2. Reads the file and checks it contains the cookie from C<auth_start>.

=item 3. C<stat>s the file to obtain the owning UID.

=item 4. Deletes the temp file.

=back

On success returns C<< {uid => <uid>, username => "<name>"} >> -- plus
C<< groups => [...] >> when a permission policy is configured (see
L</"PERMISSIONS">). The connection is now considered authenticated;
subsequent handlers can inspect C<< $ctx->uid >>, C<< $ctx->username >>, and
C<< $ctx->groups >>.

=back

=head1 USER VERIFICATION

The ownership challenge lets the server verify which Unix user is on the other
end of a connection without any password or token. Because the OS assigns file
ownership based on the creating process's effective UID, a client that can write
a correctly-named cookie file owned by UID I<N> must be running as UID I<N>.

    # Server side
    my $server = POE::Component::Server::JSONUnix->spawn(
        socket_path   => '/tmp/app.sock',
        auth_required => 1,           # reject other commands until authed
    );

    $server->register(
        whoami => sub {
            my ($server, $req, $ctx) = @_;
            return { uid => $ctx->uid, username => $ctx->username };
        },
    );

    # Client side (pseudo-code)
    send({ command => 'auth_start' });
    my $res = recv();                  # {cookie => "...", temp_dir => "/tmp"}

    my $path = "$res->{temp_dir}/verify_$$";
    open(my $fh, '>', $path) or die $!;
    print $fh $res->{cookie};
    close $fh;

    send({ command => 'auth_verify', args => { path => $path } });
    my $auth = recv();                 # {uid => 1000, username => "alice"}

    send({ command => 'whoami' });
    my $me = recv();                   # {uid => 1000, username => "alice"}

=head1 PERMISSIONS

An optional per-command permission layer on top of L</"USER VERIFICATION">.
It is enabled by passing a C<permissions> hash reference to L</spawn>; when
the argument is absent, nothing changes -- no policy is enforced, no group
lookups happen, and every response looks exactly as it did before.

    my $server = POE::Component::Server::JSONUnix->spawn(
        socket_path => '/tmp/app.sock',
        permissions => {
            default  => 'deny',
            commands => {
                status   => 'allow',                        # anyone, even unauthenticated
                reboot   => { groups => ['wheel'] },
                shutdown => { users  => [ 'root', 0 ] },    # names or numeric ids
                debug    => {
                    users      => ['zane'],
                    deny_users => ['nobody'],
                    check      => sub {
                        my ( $server, $ctx, $command ) = @_;
                        return $ctx->request->{args}{dry_run};
                    },
                },
            },
        },
        commands => { ... },
    );

=head2 Policy structure

C<default> ('allow' or 'deny', default 'allow') applies to every command that
has no entry under C<commands> and no C<%DEFAULT%> fallback (see below).
Each entry under C<commands> is either the string C<'allow'>, the string
C<'deny'>, or a hash reference with any of the following keys. Entries
consisting only of digits are treated as UIDs/GIDs; anything else as a name.

=head3 users

Array reference of usernames and/or numeric UIDs. Any match allows.

=head3 groups

Array reference of group names and/or numeric GIDs. Any match allows.
Secondary (supplementary) group memberships count, not just the user's
primary group.

=head3 deny_users, deny_groups

Same formats as C<users> and C<groups>; a match denies, and denies win over
every allow.

=head3 check

Code reference called as C<< $check->($server, $ctx, $command_name) >>; a
true return allows. An escape hatch for rules the lists cannot express. If
it dies, the request is denied (fail closed).

=head3 %DEFAULT%

Not a rule key but a special entry I<name> under C<commands>: its rule (any
of the forms above, string or hash) is used for every command -- known or not
-- that has no entry of its own, taking precedence over the C<default>
string. This lets the fallback be a full user/group rule rather than just
'allow' or 'deny':

    permissions => {
        commands => {
            '%DEFAULT%' => { groups => ['staff'] },    # everything not listed
            status      => 'allow',                    # except these
            reboot      => { groups => ['wheel'] },
        },
    },

When a C<%DEFAULT%> entry is present, C<default> still serves as the last
resort for rules that contain only deny lists (see L</"Evaluation order">).

=head2 Evaluation order

C<auth_start> and C<auth_verify> are always allowed -- the handshake must be
reachable, or nobody could ever gain the identity the policy is written in
terms of. For everything else: a hash-form rule requires authentication (even
when C<auth_required> is off globally), unauthenticated requests to such
commands are refused with C<< code => 'auth_required' >>. Then deny lists,
then allow lists and C<check> (any match allows). A command with no entry of
its own falls back to the C<%DEFAULT%> entry if one exists, and finally --
with no entry at all, or for entries with only deny lists -- to the
C<default> string. Refusals
are ordinary error responses carrying C<< code => 'permission_denied' >>:

    {"id":7,"status":"error","code":"permission_denied",
     "error":"permission denied: user 'alice' may not run 'reboot'"}

The permission check runs before the unknown-command check, so a default-deny
server does not reveal which commands exist to callers who may not run them.
For the same reason the built-in C<commands> command lists only the commands
the caller may currently run when a policy is configured.

=head2 Where groups come from

Group membership is resolved with perl's C<getpwuid>/C<getgrent> family,
which routes through the platform's NSS (or local equivalent) -- so C</etc/group>,
LDAP, sssd, NIS, and so on all behave identically, on any Unix. The
resolution collects the primary group from the passwd entry plus every
secondary group that lists the user as a member.

Because those lookups can be slow on network-backed systems, they are done at
most once per connection: at C<auth_verify> time when a policy is configured
(the result is also included in the C<auth_verify> response as C<groups>),
and cached on the connection for every later check. A user's group changes
therefore take effect on their next connection, which matches how Unix logins
behave.

Note that this reflects the user's I<configured> membership, not the peer
process's current credential set: a process that dropped a supplementary
group still counts as a member here. The policy is about who the user is, as
proven by the ownership challenge, not about the process's kernel
credentials.

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
