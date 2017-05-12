#
# This file is part of POE-Component-Client-SimpleFTP
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package POE::Component::Client::SimpleFTP;
# git description: release-0.003-11-g9ec2c28
$POE::Component::Client::SimpleFTP::VERSION = '0.004';
our $AUTHORITY = 'cpan:APOCAL';

# ABSTRACT: A simple FTP client library for POE

use POE::Component::Client::SimpleFTP::Utils qw( :code EOL );
use MooseX::POE::SweetArgs;
use POE;
use POE::Wheel::SocketFactory;
use POE::Wheel::ReadWrite;
use POE::Filter::Stream;
use POE::Filter::Line;
use POE::Driver::SysRW;
use Socket qw( INADDR_ANY AF_INET SOCK_STREAM unpack_sockaddr_in inet_ntoa );

BEGIN {

#pod =func DEBUG
#pod
#pod Enable this if you want to get debugging output. Do it like this:
#pod
#pod 	sub POE::Component::Client::SimpleFTP::DEBUG () { 1 }
#pod 	use POE::Component::Client::SimpleFTP;
#pod
#pod The default is: false
#pod
#pod =cut

	if ( ! defined &DEBUG ) { *DEBUG = sub () { 0 } }
}

#pod =attr alias
#pod
#pod The alias this component will use. You can send commands to the ftpd in 2 ways:
#pod
#pod 	my $ftp = POE::Component::Client::SimpleFTP->new( alias => "ftp", ... );
#pod 	$poe_kernel->post( 'ftp', 'cd', 'foobar' );
#pod
#pod 	# Or, you can use the yield sub:
#pod 	$ftp->yield( 'cd', 'foobar' );
#pod
#pod The default is: ftp
#pod
#pod =cut

has alias => (
	isa => 'Str',
	is => 'ro',
	default => 'ftp',
);

#pod =attr username
#pod
#pod The FTP username you will be sending to the server.
#pod
#pod required.
#pod
#pod =cut

has username => (
	isa => 'Str',
	is => 'ro',
	required => 1,
);

#pod =attr password
#pod
#pod The FTP password you will be sending to the server.
#pod
#pod required.
#pod
#pod =cut

has password => (
	isa => 'Str',
	is => 'ro',
	required => 1,
);

#pod =attr remote_addr
#pod
#pod The IP address of the FTP server to connect to. Can be a DNS hostname or IPv4/6 string.
#pod
#pod required.
#pod
#pod =cut

has remote_addr => (
	isa => 'Str',
	is => 'ro',
	required => 1,
);

#pod =attr remote_port
#pod
#pod The port of the FTP server to connect to.
#pod
#pod The default is: 21
#pod
#pod =cut

has remote_port => (
	isa => 'Int',
	is => 'ro',
	default => 21,
);

#pod =attr local_addr
#pod
#pod The local IP address to bind to for all connections to the server.
#pod
#pod The default is: INADDR_ANY ( let the OS decide )
#pod
#pod =cut

has local_addr => (
	isa => 'Str',
	is => 'ro',
	default => INADDR_ANY,
);

#pod =attr local_port
#pod
#pod The local port to bind to for the control connection to the server. If you need to change the data connection's port, please
#pod change the L</local_data_port> attribute.
#pod
#pod The default is: 0 ( let the OS decide )
#pod
#pod =cut

has local_port => (
	isa => 'Int',
	is => 'ro',
	default => 0,
);

#pod =attr local_data_port
#pod
#pod The local port to bind to for the data connection to the server. Must be a different port than the L</local_port> attribute!
#pod
#pod The default is: 0 ( let the OS decide )
#pod
#pod =cut

has local_data_port => (
	isa => 'Int',
	is => 'ro',
	default => 0,
);

#pod =attr tls_cmd
#pod
#pod A boolean value to enable/disable TLS encryption of the command connection. If you want to use this,
#pod you must have L<POE::Component::SSLify> installed!
#pod
#pod The default is: false
#pod
#pod =cut

has tls_cmd => (
	isa => 'Bool',
	is => 'ro',
	writer => '_set_tls_cmd',
	default => 0,
);

#pod =attr tls_data
#pod
#pod A boolean value to enable/disable TLS encryption of the data connection. If you want to use this,
#pod you must have L<POE::Component::SSLify> installed!
#pod
#pod The default is: false
#pod
#pod =cut

has tls_data => (
	isa => 'Bool',
	is => 'ro',
	writer => '_set_tls_data',
	default => 0,
);

#pod =attr timeout
#pod
#pod A value specifying the timeout in seconds for the initial connection to the FTP server.
#pod
#pod The default is: 120
#pod
#pod =cut

has timeout => (
	isa => 'Int',
	is => 'ro',
	default => 120,
);

#pod =attr connection_mode
#pod
#pod Determine what connection mode we will be using when opening the data connection to the server. In "active" mode,
#pod the server will be connecting to us. In "passive" mode we will be connecting to the server. You usually need "passive" mode
#pod if you are behind a firewall.
#pod
#pod The default is: passive
#pod
#pod =cut

{
	use Moose::Util::TypeConstraints;

	has connection_mode => (
		isa => enum( [ qw( active passive ) ] ),
		is => 'ro',
		default => 'passive',
	);
}

### internal attributes

# the socketfactory/readwrite wheels for the command connection
has cmd_sf => (
	isa => 'Maybe[POE::Wheel::SocketFactory]',
	is => 'rw',
	init_arg => undef,
);

has cmd_rw => (
	isa => 'Maybe[POE::Wheel::ReadWrite]',
	is => 'rw',
	init_arg => undef,
);

# the socketfactory/readwrite wheels for the data connection
has data_sf => (
	isa => 'Maybe[POE::Wheel::SocketFactory]',
	is => 'rw',
	init_arg => undef,
);

has data_rw => (
	isa => 'Maybe[POE::Wheel::ReadWrite]',
	is => 'rw',
	init_arg => undef,
);

{
	use Moose::Util::TypeConstraints;

	# it is valid until the next complex command, then we check this to see
	# what we need to do
	# A = ascii
	# I = image
	has data_type => (
		isa => enum( [ qw( A I ) ] ),
		is => 'rw',
		init_arg => undef,
		predicate => '_has_data_type',
	);
}

# holds data for multi-line replies
has input_buffer => (
	isa => 'Maybe[Str]',
	is => 'rw',
	init_arg => undef,
	default => undef,
);

has input_buffer_code => (
	isa => 'Int',
	is => 'rw',
	init_arg => undef,
);

# the session that spawned us and receives events from us
has _master => (
	isa => 'Int',
	is => 'rw',
	init_arg => undef,
);

# the internal state of the connection
has state => (
	isa => 'Str',
	is => 'rw',
	default => 'connect',
	init_arg => undef,
#	( DEBUG ? ( trigger => sub {
#		my( $self, $new, $old ) = @_;
#		warn "switching from state($old) to state($new)\n";
#		return;
#	} ) : () ),
);

# holds what "simple" command we are processing when state is 'simple_command'
has simple_command => (
	isa => 'Str',
	is => 'rw',
	init_arg => undef,
#	( DEBUG ? ( trigger => sub {
#                my( $self, $new, $old ) = @_;
#                warn "switching from simple_command($old) to simple_command($new)\n";
#                return;
#        } ) : () ),
);

# holds whatever data the command needs
has command_data => (
	isa => 'Any',
	is => 'rw',
	default => sub { {} },
	init_arg => undef,
#	( DEBUG ? ( trigger => sub {
#                my( $self, $new, $old ) = @_;
#use Data::Dumper::Concise;
#                warn "switching from command_data(" . Dumper($old) . ") to command_data(" . Dumper($new) . ")\n";
#                return;
#        } ) : () ),
);

# translation from posted events to ftp commands
my %command_map = (
	'cd'		=> "CWD",
	'mkdir'		=> "MKD",
	'rmdir'		=> "RMD",
	'ls'		=> "LIST",
	'dir'		=> "NLST",
	'get'		=> "RETR",
	'put'		=> "STOR",
	'delete'	=> "DELE",
	'quote'		=> "QUOT",
	'disconnect'	=> "QUIT",
	'features'	=> "FEAT",
	'options'	=> "OPTS",
);

my @simple_commands = ( qw(
	cdup mdtm noop pwd site size stat syst help acct smnt
	cd cwd
	dele delete
	mkd mkdir
	rmd rmdir
	quot quote
	quit disconnect
	feat features
	opts options
) );

my @complex_commands = ( qw(
	list ls
	nlst dir
	retr get
	stor stou put
) );

# a simple command that forces shutdown
event shutdown => sub {
	my $self = shift;

	$self->_shutdown;
	return;
};

# build our "simple" command handlers
foreach my $cmd ( @simple_commands ) {
	event $cmd => sub {
		my( $self, @args ) = @_;
		my $command = $cmd;

		# ignore commands if we are shutting down
		return if $self->state eq 'shutdown';

		# are we already sending a command?
		if ( $self->state ne 'idle' ) {
			# special-case the quit/disconnect methods
			if ( $cmd =~ /^(?:quit|disconnect)$/ ) {
				$self->_shutdown;
				return;
			} else {
				die "Unable to send '$cmd' because we are processing " . $self->state;
			}
		}

		# do we need to translate the command to the actual FTP command?
		if ( exists $command_map{ $cmd } ) {
			$command = $command_map{ $cmd };
		}

		# store the command we are processing then send it
		warn "doing simple_command($cmd) with data(" . join( ' ', @args ) . ")\n" if DEBUG;
		$self->simple_command( $cmd );
		$self->command_data( \@args );
		$self->command( 'simple_command', $command, @args );
		return;
	};
}

# build our "complex" command handlers ( they require a data connection )
foreach my $cmd ( @complex_commands ) {
	event $cmd => sub {
		my( $self, @args ) = @_;

		# ignore commands if we are shutting down
		return if $self->state eq 'shutdown';

		# are we already sending a command?
		if ( $self->state ne 'idle' ) {
			die "Unable to send '$cmd' because we are processing " . $self->state;
		}

		# start doing this command!
		warn "doing complex command($cmd) with data(" . join( ' ', @args ) . ")\n" if DEBUG;
		$self->command_data( {
			'cmd' => $cmd,
			'data' => \@args,
		} );
		if ( $cmd =~ /^(?:ls|dir|list|nlst)$/ ) {
			$self->_prepare_listing;
		} elsif ( $cmd =~ /^(?:get|put|retr|stor|stou)$/ ) {
			$self->_prepare_transfer;
		}

		return;
	};
}

# rename support
foreach my $cmd ( qw( rename mv ) ) {
	event $cmd => sub {
		my( $self, $from, $to ) = @_;

		# ignore commands if we are shutting down
		return if $self->state eq 'shutdown';

		# are we already sending a command?
		if ( $self->state ne 'idle' ) {
			die "Unable to send '$cmd' because we are processing " . $self->state;
		}

		# Start the rename!
		$self->command_data( {
			from => $from,
			to => $to,
		} );
		$self->command( 'rename_start', 'RNFR', $from );

		return;
	};
}

sub _prepare_listing {
	my $self = shift;

	# do we need to set the TYPE?
	if ( ! $self->_has_data_type or $self->data_type eq 'I' ) {
		$self->command_data->{'type'} = 'A';
		$self->command( 'complex_type', 'TYPE', 'A' );
	} else {
		# Okay, proceed to start the data connection stuff
		$self->_start_data_connection;
	}
}

sub _prepare_transfer {
	my $self = shift;

	# do we need to set the TYPE?
	if ( ! $self->_has_data_type or $self->data_type eq 'A' ) {
		$self->command_data->{'type'} = 'I';
		$self->command( 'complex_type', 'TYPE', 'I' );
	} else {
		# Okay, proceed to start the data connection stuff
		$self->_start_data_connection;
	}
}

sub _start_data_connection {
	my $self = shift;

	# okay, we go ahead with the PASV/PORT command
	if ( $self->connection_mode eq 'passive' ) {
		$self->command( 'complex_pasv', 'PASV' );
	} else {
		# Okay, create our listening socket
		$self->_create_data_connection;
	}
}

# build our data complex command handlers
foreach my $cmd ( qw( put stor stou ) ) {
	event "${cmd}_data" => sub {
		my( $self, $input ) = @_;

		# don't print the input as it could be binary stuff
		warn "received ${cmd}_data\n" if DEBUG;

		# ignore commands if we are shutting down
		return if $self->state eq 'shutdown';

		# should only happen in complex state
		if ( $self->state eq 'complex_data' ) {
			# This should only happen for put commands
			if ( $self->command_data->{'cmd'} eq $cmd ) {
				# send the data to our rw wheel
				if ( defined $self->data_rw ) {
					$self->data_rw->put( $input );
				} else {
					# TODO maybe we shouldn't die here? Just warn and let the user handle the error?
					die "got ${cmd}_data when we are not connected!";
				}
			} else {
				die "got ${cmd}_data when we are not doing a STOR";
			}
		} else {
			die "got ${cmd}_data when we are in wrong state: " . $self->state;
		}

		return;
	};

	event "${cmd}_close" => sub {
		my $self = shift;

		warn "received ${cmd}_close\n" if DEBUG;

		# ignore commands if we are shutting down
		return if $self->state eq 'shutdown';

		# should only happen in complex state
		if ( $self->state eq 'complex_data' ) {
			# This should only happen for put commands
			if ( $self->command_data->{'cmd'} eq $cmd ) {
				# kill the rw wheel, disconnecting from the server
				if ( defined $self->data_rw ) {
					$self->_process_complex_closed;
				} else {
					# maybe a timing issue, server killed the connection while this event was in the queue?
					# then the data_rw_error event would have caught this and sent the appropriate error message
					warn "unable to ${cmd}_close as wheel is gone\n" if DEBUG;
				}
			} else {
				die "got ${cmd}_close when we are not doing a STOR";
			}
		} else {
			die "got ${cmd}_close when we are in wrong state: " . $self->state;
		}

		return;
	};
}

sub BUILD {
	my $self = shift;

	# Did we enable TLS mode?
	if ( $self->tls_cmd or $self->tls_data ) {
		eval 'require POE::Component::SSLify';
		if ( $@ ) {
			warn "Unable to use SSLify: $@\n";
			$self->_set_tls_cmd( 0 );
			$self->_set_tls_data( 0 );
		}
	}

	# Make sure that the local_port and local_data_port is different!
	if ( $self->local_port == $self->local_data_port and $self->local_port != 0 ) {
		die "Please specify different local_port and local_data_port settings!";
	}

	# In order to use active mode connection, we MUST provide a local IP address to bind
	# otherwise getsockname() on INADDR_ANY unsurprisingly returns 0.0.0.0 which is worthless for the PORT command!
	if ( $self->connection_mode eq 'active' and $self->local_addr eq '0.0.0.0' ) {
		die "Please specify a local_addr address to bind to for active connections!";
	}

	# Figure out who called us so we store it for events
	$self->_master( $poe_kernel->get_active_session->ID );
}

# Okay, go connect to the host!
sub START {
	my $self = shift;

	warn "starting\n" if DEBUG;

	$poe_kernel->alias_set( $self->alias );

	# set a timeout before trying to connect
	$poe_kernel->delay( 'timeout_event' => $self->timeout );
	$self->cmd_sf( POE::Wheel::SocketFactory->new(
		SocketDomain	=> AF_INET,
		SocketType	=> SOCK_STREAM,
		SocketProtocol	=> 'tcp',
		RemoteAddress	=> $self->remote_addr,
		RemotePort	=> $self->remote_port,
		BindAddr	=> $self->local_addr,
		BindPort	=> $self->local_port,
		SuccessEvent	=> 'cmd_sf_connected',
		FailureEvent	=> 'cmd_sf_error'
	) );

	return;
}

# helper sub to simplify sending events to the master
sub _send_master {
	my( $self, $event, @args ) = @_;

	warn "telling master about event $event\n" if DEBUG;

	$poe_kernel->post( $self->_master, $event, @args );
}

# shutdown the connection
sub _shutdown {
	my $self = shift;

	warn "shutdown\n" if DEBUG;
	$self->state( 'shutdown' );

	# destroy our wheels
	$self->cmd_sf( undef );
	$self->cmd_rw( undef );
	$self->data_sf( undef );
	$self->data_rw( undef );

	# remove the timeout if it exists
	$poe_kernel->delay( 'timeout_event' );

	$poe_kernel->alias_remove( $self->alias );
}

#pod =method yield
#pod
#pod This method provides an alternative object based means of posting events to the component.
#pod First argument is the event to post, following arguments are sent as arguments to the resultant post.
#pod
#pod 	my $ftp = POE::Component::Client::SimpleFTP->new( alias => "ftp", ... );
#pod 	$ftp->yield( 'cd', 'foobar' );
#pod
#pod 	# equivalent to:
#pod 	$poe_kernel->post( $ftp->alias, 'cd', 'foobar' );
#pod
#pod =cut

sub yield {
	my( $self, @args ) = @_;
	$poe_kernel->post( $self->get_session_id, @args );
}

event _child => sub {
	return;
};

event timeout_event => sub {
	my $self = shift;

	# Okay, we timed out doing something
	if ( $self->state eq 'connect' ) {
		# failed to connect to the server
		$self->_send_master( 'connect_error', 0, 'timedout' );

		# nothing else to do...
		$self->_shutdown;
	} elsif ( $self->state eq 'complex_sf' ) {
		# timed out waiting for the data connection

		# since this is a pre-data-connection error, the complex command is done
		$self->_process_complex_error( 0, 'timedout' );
		$self->state( 'idle' );
	} else {
		die "unknown state in timeout_event: " . $self->state;
	}

	return;
};

event cmd_sf_connected => sub {
	my( $self, $fh, $host, $port, $wheel_id ) = @_;

	warn "cmd_sf_connected\n" if DEBUG;

	# remove the timeout
	$poe_kernel->delay( 'timeout_event' );

	# convert it into a readwrite wheel
	$self->cmd_rw( POE::Wheel::ReadWrite->new(
		Handle	=> $fh,
		Filter	=> POE::Filter::Line->new( Literal => EOL ),
		Driver	=> POE::Driver::SysRW->new,
		InputEvent	=> 'cmd_rw_input',
		ErrorEvent	=> 'cmd_rw_error',
	) );

	return;
};

event cmd_sf_error => sub {
	my( $self, $operation, $errnum, $errstr, $wheel_id ) = @_;

	warn "cmd_sf_error $operation $errnum $errstr\n" if DEBUG;

	$self->_send_master( 'connect_error', 0, "$operation error $errnum: $errstr" );

	# nothing else to do...
	$self->_shutdown;

	return;
};

event cmd_rw_input => sub {
	my( $self, $input, $wheel_id ) = @_;

	warn "cmd_rw_input(" . $self->state . "): '$input'\n" if DEBUG;

	# some ftpds are zany!
#calling _ftpd_simple_command to process 221:Goodbye.
#shutdown
#switching from state(simple_command) to state(shutdown)
#cmd_rw_input(shutdown): '500 OOPS: priv_sock_get_cmd'
#calling _ftpd_shutdown to process 500:OOPS: priv_sock_get_cmd
#Can't locate object method "_ftpd_shutdown" via package "POE::Component::Client::SimpleFTP" at /usr/local/share/perl/5.18.2/POE/Component/Client/SimpleFTP.pm line 790.
	return if $self->state eq 'shutdown';

	# parse the input according to RFC 959
	# TODO put this code in POE::Filter::FTP or something?
	my( $code, $line );
	if ( $input =~ /^(\d\d\d)(\-?)(.*)$/ ) {
		$code = $1;
		my( $minus, $string ) = ( $2, $3 );
		$string =~ s/^\s+//;
		$string =~ s/\s+$//;

		# handle multi-line replies
		if ( length $minus ) {
			if ( defined $self->input_buffer ) {
				die "ftpd sent different multi-line codes!" if $self->input_buffer_code ne $code;
				$self->input_buffer( $self->input_buffer . "\n" . $string );
                        } else {
				warn "begin of multi-line($code): '$string'\n" if DEBUG;
				$self->input_buffer( $string );
                        }
			$self->input_buffer_code( $code );
			return;
		} else {
			# end of multi-line reply?
			if ( defined $self->input_buffer ) {
				# Make sure the code matches!
				if ( $self->input_buffer_code != $code ) {
					die "ftpd sent invalid reply: $input";
				} else {
					warn "end of multi-line: '$string'\n" if DEBUG;
					$line = $self->input_buffer . "\n" . $string;
					$self->input_buffer( undef );
				}
			} else {
				$line = $string;
			}
		}
	} else {
		# If we are in a multi-line reply, just collect the input
		if ( defined $self->input_buffer ) {
			# per the RFC, the first character should be padded by a space if needed
			$input =~ s/^\s//;
			warn "got multi-line input: '$input'\n" if DEBUG;
			$self->input_buffer( $self->input_buffer . "\n" . $input );
			return;
		} else {
			die "ftpd sent invalid reply: $input";
		}
	}

	# process the input, depending on our state
	my $subref = "_ftpd_" . $self->state;
	if ( $self->state eq 'complex_data' ) {
		# okay, we got input from the ftpd before the complex data is closed, so we buffer it...
		if ( exists $self->command_data->{'cmd_pending'} ) {
			# ftpd sent data faster than we could get the command!
			warn "executing pending command data\n" if DEBUG;
			$subref = '_ftpd_complex_done';
		} else {
			warn "buffering command data\n" if DEBUG;
			$self->command_data->{'cmd_buffer'} = [$code, $line];
			return;
		}
	}

	warn "calling $subref to process $code:$line\n" if DEBUG;
	$self->$subref( $code, $line );

	return;
};

event cmd_rw_error => sub {
	my( $self, $operation, $errnum, $errstr, $wheel_id) = @_;

	warn "cmd_rw_error $operation $errnum $errstr\n" if DEBUG;

	$self->_send_master( 'connect_error', 0, "$operation error $errnum: $errstr" );

	# nothing else to do...
	$self->_shutdown;

	return;
};

# sets the state for a command and sends it over the control connection
sub command {
	my( $self, $state, $cmd, @args ) = @_;

	# If we don't have a readwrite wheel, then we can't send anything!
	if ( ! defined $self->cmd_rw ) {
		die "Unable to send '$cmd' as we aren't connected!";
	}

	# change to the specified state, then send the args!
	$self->state( $state );
	if ( $cmd eq 'QUOT' ) {
		# user-defined string, send it as-is!
		$cmd = shift @args;
	}

	$cmd = uc $cmd; # to make sure
	my $cmdstr = join( ' ', $cmd, @args );
	warn "sending command '$cmdstr'\n" if DEBUG;
	$self->cmd_rw->put( $cmdstr );
}

sub _ftpd_idle {
	my( $self, $code, $reply ) = @_;

	die "unexpected text while we are idle: $code $reply";
}

# the first line of text we received from the ftpd ( the greeting )
sub _ftpd_connect {
	my( $self, $code, $reply ) = @_;

	if ( code_success( $code ) ) {
		$self->_send_master( 'connected', $reply );

		# do we want TLS?
		if ( $self->tls_cmd ) {
			# begin TLS authentication procedure, as per RFC 2228 / 4217
			$self->command( 'tls_cmd', 'AUTH', 'TLS' );
		} else {
			# send the username!
			$self->command( 'user', 'USER', $self->username );
		}
	} else {
		$self->_send_master( 'connect_error', $code, $reply );

		# nothing else to do...
		$self->_shutdown;
	}
}

sub _ftpd_tls_cmd {
	my( $self, $code, $reply ) = @_;

	if ( code_success( $code ) ) {
		# Okay, time to SSLify the connection!
		my $socket = $self->cmd_rw->get_input_handle;
		$self->cmd_rw( undef );

		eval { $socket = POE::Component::SSLify::Client_SSLify( $socket, 'tlsv1' ) };
		if ( $@ ) {
			die "Unable to SSLify control connection: $@";
		}

		# set up the rw wheel again
		$self->cmd_rw( POE::Wheel::ReadWrite->new(
			Handle	=> $socket,
			Filter	=> POE::Filter::Line->new( Literal => EOL ),
			Driver	=> POE::Driver::SysRW->new,
			InputEvent	=> 'rw_input',
			ErrorEvent	=> 'rw_error',
		) );

		# Now, send the username!
		$self->command( 'user', 'USER', $self->username );
	} else {
		# server probably doesn't support AUTH TLS
		$self->_send_master( 'login_error', $code, $reply );
		$self->state( 'idle' );
	}
}

sub _ftpd_pbsz {
	my( $self, $code, $reply ) = @_;

	if ( code_success( $code ) ) {
		$self->command( 'prot', 'PROT', 'P' );
	} else {
		$self->_send_master( 'login_error', $code, $reply );
		$self->state( 'idle' );
	}
}

sub _ftpd_prot {
	my( $self, $code, $reply ) = @_;

	if ( code_success( $code ) ) {
		my $banner = $reply;
		if ( exists $self->command_data->{'orig_banner'} ) {
			$banner = (delete $self->command_data->{'orig_banner'}) . "\n" . $reply;
		}
		$self->_send_master( 'authenticated', $banner );
	} else {
		$self->_send_master( 'login_error', $code, $reply );
	}

	$self->state( 'idle' );
}

sub _ftpd_user {
	my( $self, $code, $reply ) = @_;

	if ( code_success( $code ) ) {
		# no need for password ( probably anonymous account )
		$self->_prepare_tls_stuff( $reply );
	} elsif ( code_intermediate( $code ) ) {
		# send the password!
		$self->command( 'password', 'PASS', $self->password );
	} else {
		$self->_send_master( 'login_error', $code, $reply );
		$self->state( 'idle' );
	}
}

sub _prepare_tls_stuff {
	my( $self, $reply ) = @_;

	# do we need to setup the data channel TLS stuff?
	if ( $self->tls_data ) {
		# cache the original reply
		$self->command_data->{'orig_banner'} = $reply;

		# TODO is 0 a good default?
		$self->command( 'pbsz', 'PBSZ', 0 );
	} else {
		$self->_send_master( 'authenticated', $reply );
		$self->state( 'idle' );
	}
}

sub _ftpd_password {
	my( $self, $code, $reply ) = @_;

	if ( code_success( $code ) ) {
		$self->_prepare_tls_stuff( $reply );
	} else {
		$self->_send_master( 'login_error', $code, $reply );
		$self->state( 'idle' );
	}
}

sub _ftpd_simple_command {
	my( $self, $code, $reply ) = @_;

	# special-case for quit
	if ( $self->simple_command =~ /^(?:quit|disconnect)$/ ) {
		$self->_shutdown;
		return;
	}

	my $event = $self->simple_command;
	if ( ! code_success( $code ) ) {
		$event .= '_error';
	}
	$self->_send_master( $event, $code, $reply, @{ $self->command_data } );

	$self->command_data( undef );
	$self->state( 'idle' );
}

sub _ftpd_complex_type {
	my( $self, $code, $reply ) = @_;

	if ( code_success( $code ) ) {
		$self->data_type( delete $self->command_data->{'type'} );
		$self->_start_data_connection;
	} else {
		# since this is a pre-data-connection error, the complex command is done
		$self->_process_complex_error( $code, $reply );
		$self->state( 'idle' );
	}
}

sub _ftpd_complex_pasv {
	my( $self, $code, $reply ) = @_;

	if ( code_success( $code ) ) {
		# Got the server's data!
		# TODO the RFC is fuzzy about it, but can the port digit be negative?!?!
		# http://cr.yp.to/ftp/retr.html
		my @data = $reply =~ /(\d+),(\d+),(\d+),(\d+),(\d+),(\d+)/;
		$self->command_data->{'ip'} = join '.', @data[0 .. 3];
		$self->command_data->{'port'} = $data[4]*256 + $data[5];

		# Okay, create our listening socket
		$self->_create_data_connection;
	} else {
		# since this is a pre-data-connection error, the complex command is done
		$self->_process_complex_error( $code, $reply );
		$self->state( 'idle' );
	}
}

sub _ftpd_complex_port {
	my( $self, $code, $reply ) = @_;

	if ( code_success( $code ) ) {
		# now, send the actual complex command :)
		$self->_process_complex_command;
	} else {
		# since this is a pre-data-connection error, the complex command is done
		$self->_process_complex_error( $code, $reply );
		$self->state( 'idle' );
	}
}

sub _create_data_connection {
	my $self = shift;

	# we now transition to the "complex" state
	# the "real" state is kept in $self->command_data->{cmd}

	# the arguments to socketfactory depend on whether we are in active or passive mode
	my %sf_args = (
		SocketDomain	=> AF_INET,
		SocketType	=> SOCK_STREAM,
		SocketProtocol	=> 'tcp',
		SuccessEvent	=> 'data_sf_connected',
		FailureEvent	=> 'data_sf_error',

		BindAddr	=> $self->local_addr,
		BindPort	=> $self->local_data_port,
	);

	if ( $self->connection_mode eq 'passive' ) {
		# use the ip/port we already received
		$sf_args{ RemoteAddress } = $self->command_data->{'ip'};
		$sf_args{ RemotePort } = $self->command_data->{'port'};
	} else {
		# enable the Reuse param so we can sanely use the same local port
		$sf_args{ Reuse } = 1;
	}

	# create the socketfactory!
	$poe_kernel->delay( 'timeout_event' => $self->timeout );
	$self->data_sf( POE::Wheel::SocketFactory->new( %sf_args ) );

	# Now that we've created the SF, do we need to send the PORT data?
	if ( $self->connection_mode eq 'active' ) {
		# TODO what if SF had an error binding to the socket?
		my $socket = $self->data_sf->getsockname;
		my( $port, $addr ) = unpack_sockaddr_in( $socket );

		# TODO why won't getsockname give me the right ip????
#		warn "GOT " . inet_ntoa( $addr ) . ":$port" if DEBUG;
#		$addr = inet_ntoa( $addr ); ( always returns 0.0.0.0, but netstat shows it binding on the right ip! )
		$addr = $self->local_addr;

		my @addr = split( /\./, $addr );
		my @port = ( int( $port / 256 ), $port % 256 );
		$self->command( 'complex_port', 'PORT', join( ',', @addr, @port ) );
	} else {
		# wait for the connection to server
		$self->state( 'complex_sf' );
	}
}

event data_sf_connected => sub {
	my( $self, $fh, $host, $port, $wheel_id ) = @_;

	# TODO what if we get multiple connections?
	# probably can happen if an attacker attacks us while we use active PORT connection

	warn "data_sf_connected\n" if DEBUG;

	# all done with the SF wheel
	$self->data_sf( undef );

	# kill the timeout timer
	$poe_kernel->delay( 'timeout_event' );

	# args for the RW wheel
	my %rw_args = (
		Handle	=> $fh,
		Driver	=> POE::Driver::SysRW->new,
		InputEvent	=> 'data_rw_input',
		ErrorEvent	=> 'data_rw_error',
		FlushedEvent	=> 'data_rw_flushed',
	);
	if ( $self->command_data->{'cmd'} =~ /^(?:ls|dir|list|nlst)$/ ) {
		$rw_args{'Filter'} = POE::Filter::Line->new( InputLiteral => EOL );
	} else {
		$rw_args{'Filter'} = POE::Filter::Stream->new;
	}

	# convert it into a readwrite wheel
	$self->data_rw( POE::Wheel::ReadWrite->new( %rw_args ) );

	# do we need to send the actual command?
	if ( $self->connection_mode eq 'passive' ) {
		$self->_process_complex_command;
	}

	return;
};

sub _process_complex_command {
	my $self = shift;

	my $cmd = $self->command_data->{'cmd'};

	# do we need to translate the command?
	if ( exists $command_map{ $cmd } ) {
		$cmd = $command_map{ $cmd };
	} else {
		$cmd = uc( $cmd );
	}

	# since the code in sub command doesn't like sending undef's we have to check it here
	if ( defined $self->command_data->{'data'} ) {
		$self->command( 'complex_start', $cmd, @{ $self->command_data->{'data'} } );
	} else {
		$self->command( 'complex_start', $cmd );
	}
}

event data_sf_error => sub {
	my( $self, $operation, $errnum, $errstr, $wheel_id ) = @_;

	warn "data_sf_error: $operation $errnum $errstr\n" if DEBUG;

	# some sort of error?
	if ( $self->state eq 'complex_sf' ) {
		$self->_process_complex_error( undef, "$operation error $errnum: $errstr" );
	} else {
		die "unexpected data_sf_error in wrong state: " . $self->state;
	}
};

sub _ftpd_complex_start {
	my( $self, $code, $reply ) = @_;

	# actually process the "start" of the command
	if ( code_preliminary( $code ) ) {
		# let the master know it's ready to send/receive stuff!
		$self->_send_master( $self->command_data->{'cmd'} . '_connected', @{ $self->command_data->{'data'} } );
		$self->state( 'complex_data' );

		# do we have any buffered data?
		if ( exists $self->command_data->{'buffer'} ) {
			warn "sending buffered chunks\n" if DEBUG;
			foreach my $chunk ( @{ $self->command_data->{'buffer'} } ) {
				$self->_send_master( $self->command_data->{'cmd'} . '_data', $chunk, @{ $self->command_data->{'data'} } );
			}
			delete $self->command_data->{'buffer'};

			# check for server sending faster than we can process
			if ( exists $self->command_data->{'cmd_pending'} ) {
				warn "fixing pending command data\n" if DEBUG;
				$self->state( 'complex_done' );
			}
		}
	} elsif ( code_success( $code ) ) {
		die "unexpected success for start of complex command: $code $reply";
	} else {
		$self->_process_complex_error( $code, $reply );
	}
}

sub _ftpd_complex_error {
	my( $self, $code, $reply ) = @_;

	# we are supposed to get some kind of error from the ftpd
	# because something screwed up while doing the data connection
	if ( code_failure( $code ) ) {
		# okay, all done!
		$self->state( 'idle' );
		$self->command_data( undef );
	} else {
		die "unexpected input while in complex_error state: $code $reply";
	}
}

sub _ftpd_complex_done {
	my( $self, $code, $reply ) = @_;

	# got the final result of the complex command!
	my $event = $self->command_data->{'cmd'};
	if ( ! code_success( $code ) ) {
		$event .= '_error';
	}
	$self->_send_master( $event, $code, $reply, @{ $self->command_data->{'data'} } );

	# clear all data for this complex command
	$self->state( 'idle' );
	$self->command_data( undef );
}

sub _process_complex_error {
	my( $self, $code, $reply ) = @_;

	# go to the error state, so we can receive whatever the ftpd wants to send to us
	$self->state( 'complex_error' );

	$self->data_sf( undef );
	$self->data_rw( undef );

	$self->_send_master( $self->command_data->{'cmd'} . '_error', $code, $reply, @{ $self->command_data->{'data'} } );

	# all done processing this complex command
	$self->command_data( undef );
}

sub _process_complex_closed {
	my $self = shift;

	# Okay, we are done with this command!
	$self->state( 'complex_done' );
	$self->data_rw( undef );

	# Did we buffer any commands?
	if ( exists $self->command_data->{'cmd_buffer'} ) {
		warn "executing buffered command reply\n" if DEBUG;
		$self->_ftpd_complex_done( @{ delete $self->command_data->{'cmd_buffer'} } );
	}

	# TODO should we send an event_closed command? I think it's superfluous...
}

event data_rw_input => sub {
	my( $self, $input, $wheel_id ) = @_;

	warn "data_rw_input: '$input'\n" if DEBUG;

	# should only happen in complex state
	if ( $self->state eq 'complex_data' ) {
		# send it back to the master
		$self->_send_master( $self->command_data->{'cmd'} . '_data', $input, @{ $self->command_data->{'data'} } );
	} elsif ( $self->state eq 'complex_start' ) {
		# oh boy, the server immediately sent us some data while we were processing the start
		# that means we have to buffer it so we correctly send it *after* we send the connected event
		warn "storing input for buffer\n" if DEBUG;
		if ( ! exists $self->command_data->{'buffer'} ) {
			$self->command_data->{'buffer'} = [ $input ];
		} else {
			push( @{ $self->command_data->{'buffer'} }, $input );
		}
	} else {
		die "unexpected data_rw_input in wrong state: " . $self->state;
	}

	return;
};

event data_rw_error => sub {
	my( $self, $operation, $errnum, $errstr, $wheel_id ) = @_;

	warn "data_rw_error: $operation $errnum $errstr\n" if DEBUG;

	# should only happen in complex state
	if ( $self->state eq 'complex_start' ) {
		# woah, sent the data faster than we started!
		$self->command_data->{'cmd_pending'} = 1;
	} elsif ( $self->state eq 'complex_data' ) {
		# Is it a normal EOF or an error?
		if ( $operation eq "read" and $errnum == 0 ) {
			# only in the put state is this a real error
			if ( $self->command_data->{'cmd'} =~ /^(?:put|stor|stou)$/ ) {
				$self->_process_complex_error( undef, "$operation error $errnum: $errstr" );
			} else {
				# otherwise it was a listing/get which means the data stream is done
				$self->_process_complex_closed;
			}
		} else {
			$self->_process_complex_error( undef, "$operation error $errnum: $errstr" );
		}
	} else {
		die "unexpected data_rw_error in wrong state: " . $self->state;
	}

	return;
};

event data_rw_flushed => sub {
	my( $self, $wheel_id ) = @_;

	warn "data_rw_flushed\n" if DEBUG;

	# should only happen in complex state
	if ( $self->state eq 'complex_data' ) {
		# This should only happen for put commands
		if ( $self->command_data->{'cmd'} =~ /^(?:put|stor|stou)$/ ) {
			$self->_send_master( $self->command_data->{'cmd'} . '_flushed', @{ $self->command_data->{'data'} } );
		} else {
			die "unexpected data_rw_flushed for complex command:" . $self->command_data->{'cmd'};
		}
	} else {
		die "unexpected data_rw_flushed in wrong state: " . $self->state;
	}

	return;
};

sub _ftpd_rename_start {
	my( $self, $code, $reply ) = @_;

	if ( code_intermediate( $code ) ) {
		# TODO should we send a rename_partial event? I think it's superfluous...
		$self->command( 'rename_done', 'RNTO', $self->command_data->{'to'} );
	} else {
		$self->_send_master( 'rename_error', $code, $reply, $self->command_data->{'from'}, $self->command_data->{'to'} );
		$self->command_data( undef );
		$self->state( 'idle' );
	}
}

sub _ftpd_rename_done {
	my( $self, $code, $reply ) = @_;

	my $event = 'rename';
	if ( ! code_success( $code ) ) {
		$event .= '_error';
	}
	$self->_send_master( $event, $code, $reply, $self->command_data->{'from'}, $self->command_data->{'to'} );

	$self->command_data( undef );
	$self->state( 'idle' );
}

no MooseX::POE::SweetArgs;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee
diff irc mailto metadata placeholders metacpan ftp

=for Pod::Coverage command START BUILD INADDR_ANY

=head1 NAME

POE::Component::Client::SimpleFTP - A simple FTP client library for POE

=head1 VERSION

  This document describes v0.004 of POE::Component::Client::SimpleFTP - released November 04, 2014 as part of POE-Component-Client-SimpleFTP.

=head1 SYNOPSIS

	# A simple FTP client logging in to a server
	use POE qw( Component::Client::SimpleFTP );

	POE::Session->create(
		inline_states => {
			_start => sub {
				POE::Component::Client::SimpleFTP->new(
					alias => "ftp",
					remote_addr => "invalid.addr",
					username => "myuser",
					password => "mypassword",
				);
				return;
			},
			authenticated => sub {
				print "LOGGED ON!\n";
				$_[KERNEL]->post( "ftp", "quit" );
				return;
			}
		},
	);
	POE::Kernel->run;

=head1 DESCRIPTION

This is a simple FTP client to use in a POE application. It's a complete rewrite of the old L<POE::Component::Client::FTP> codebase and makes
it easier to use. Most of the API/event flow is compatible, so you should have few problems porting your code to this module.

You start by creating the ftp object and wait for it to send you events. By default the caller session will get all the events directed to it,
no need to "register" for events or anything like that. Events are sent to you in the generic form of C<$command> or C<${command}_error> events.
This module will parse the FTP reply codes and determine if it is an error or not, and dispatch it to the appropriate event.

An important thing to keep in mind is that there is no command queueing done in this module. It is up to the user to know what state they are
in and to dispatch events at the right time. If a command is sent while this module is processing one, an exception will be thrown. Fortunately,
due to the way events are named, it should be easy to keep track of the event flow.

=head2 Initial Connection

When the object is created, it attempts to make a connection to the server specified in the attributes. It will automatically login with the
provided credentials. Additionally, it will enable TLS mode if you enabled the attributes L</tls_cmd> and L</tls_data>. There is a timeout timer
on the initial connection that you can tweak via setting L</timeout>.

The following events may be sent to your session:

=head3 connected

This event is sent when the initial connection to the server is established. The connection is not yet finalized, so you aren't able to send
commands yet!

The first argument is the string banner that the server sent, if any.

=head3 authenticated

This event is sent when the entire login procedure is done. At this point you can send commands to the server.

The first argument is the string banner that the server sent, if any.

=head3 connect_error

This event is sent when there's an error connecting to the server. The component will automatically destroy itself at this point, so if you
want to retry the connection, you have to make a new object.

The first argument is the error code, and the 2nd argument is the error string.

The code "0" is used here, because we never got a reply from the server. However, it is nice to have consistency with the other
event handlers, so it is supplied.

Example code: 0

Example reply: timedout

=head3 login_error

This event is sent when there's an error trying to login to the server. The component will automatically destroy itself at this point, so if you
want to retry the connection, you have to make a new object.

The first argument is the error code, and the 2nd argument is the error string.

Example code: 530

Example reply: Login incorrect.

=head2 Simple Commands

This is a class of commands that can be sent to the server after receiving the L</authenticated> event. They perform identically, and will send
the same replies back to your session. Some commands require arguments, others don't.

Normally the events will include at least 2 arguments: the FTP return code and the actual reply line from the server. If the command included
arguments, it will be supplied in the event to make identifying actions easier.

Some commands is an alias for the actual command ( cd vs cwd ) but the event name will follow the aliased command. If a cwd event is sent, the
error event is C<cwd_error>. If a cd event is sent, the error event is C<cd_error>.

	# send the cd command in an event handler somewhere
	$ftp->yield( 'cd', '/foobar' );

	# handler for the resulting event received from this component
	sub cd {
		my( $code, $reply, $path ) = @_[ ARG0 .. ARG2 ];

		# $code probably is 250
		# $reply probably is "Directory successfully changed."
		# $path will be "/foobar"
	}

	sub cd_error {
		my( $code, $reply, $path ) = @_[ ARG0 .. ARG2 ];

		# $code probably is 550
		# $reply probably is "Failed to change directory."
		# $path will be "/foobar"
	}

=head3 cwd

Changes the working directory.

Arguments: the path to change to ( required )

Example code: 250

Example reply: Directory successfully changed.

=head3 cd

An alias for L</cwd>

=head3 dele

Deletes a file.

Arguments: the file to delete ( required )

Example code: 250

Example reply: Delete operation successful.

=head3 delete

An alias for L</dele>

=head3 mkd

Creates a directory.

Arguments: the directory path to create ( required )

You can supply an absolute path or a relative path. It is up to the server to figure out where to create the directory. It's easier to use
absolute paths so you are sure that the server is creating the directory in the right place!

Remember, the FTP protocol doesn't support recursive directory creation! If C</foo> exists but C</foo/bar> doesn't, then you cannot create
C</foo/bar/baz>!

Example code: 257

Example reply: "/foo" created

=head3 mkdir

An alias for L</mkd>

=head3 rmd

Removes a directory.

Arguments: the directory path to delete ( required )

You can supply an absolute path or a relative path. It is up to the server to figure out where to delete the directory. It's easier to use
absolute paths so you are sure that the server is deleting the right directory!

Example code: 250

Example reply: Remove directory operation successful.

=head3 rmdir

An alias for L</rmd>

=head3 cdup

Changes the working directory to the parent.

Remember, there might be symlinks or other bizarre stuff going on behind the scenes! It's best to supply full pathnames to L</cwd> to be safe.

Arguments: none

Example code: 250

Example reply: Directory successfully changed.

=head3 pwd

Prints the current working directory.

Arguments: none

Example code: 257

Example reply: "/"

=head3 rename

Renames a target file to a new name.

Arguments: the old filename and the new filename

Remember, the pathnames must exist and is a valid target. Best to send absolute paths!

Example code: 250

Example reply: Rename successful.

=head3 mv

An alias for L</rename>

=head3 quit

Disconnects from the server. Behaves differently depending on the context when this command is received. After this command is sent, this
module will destroy itself and not send any more events to your session.

If this module isn't processing anything it will send the QUIT command and gracefully shutdown when it receives the server reply.

If this module is processing a command it will disconnect immediately, killing any command processing/data transfers that is happening.

If you want to force immediate shutdown, use the L</shutdown> event.

Arguments: none

=head3 disconnect

An alias for L</quit>

=head3 shutdown

Forces a shutdown of the component and kills everything.

Arguments: none

=head3 noop

Executes a no-operation command. Useful to keep the connection open or to get the round-trip latency, or whatever :)

Arguments: none

Example code: 200

Example reply: NOOP ok.

=head3 quot

Sends a quoted command to the server. Useful for sending commands that this module doesn't support.

Arguments: the actual command + arguments to send.

	$ftp->yield( 'quot', 'CRAZYCMD', @crazy_args );

=head3 quote

An alias for L</quot>

=head3 help

Gets the server's help output for a command.

Arguments: optional command to ask for help

Example code: 214

Example reply:

	The following commands are recognized.
	ABOR ACCT ALLO APPE CDUP CWD  DELE EPRT EPSV FEAT HELP LIST MDTM MKD
	MODE NLST NOOP OPTS PASS PASV PORT PWD  QUIT REIN REST RETR RMD  RNFR
	RNTO SITE SIZE SMNT STAT STOR STOU STRU SYST TYPE USER XCUP XCWD XMKD
	XPWD XRMD
	Help OK.

=head3 site

Executes a specific command that the server supports. Consult your ftp administrator or the document for the ftpd software for more information.

Arguments: the command to execute + any optional arguments.

Example code: 500

Example reply: Unknown SITE command.

=head3 stat

Receives some informational text about the current status of the connection.

BEWARE: While the RFC says this command can be sent while a data transfer is in progress, this is unimplemented!

Arguments: none

Example code: 211

Example reply:

	FTP server status:
	Connected to 192.168.0.199
	Logged in as apoc
	TYPE: ASCII
	No session bandwidth limit
	Session timeout in seconds is 300
	Control connection is plain text
	Data connections will be plain text
	At session startup, client count was 1
	vsFTPd 2.2.0 - secure, fast, stable
	End of status

=head3 syst

Gets the system information of the server.

Arguments: none

Example code: 215

Example reply: UNIX Type: L8

=head3 acct

Send the account information for your login. Generally not used, but if your server requires it you should send this immediately after getting the
L</authenticated> event.

Arguments: your account information

Example code: 502

Example reply: ACCT not implemented.

=head3 smnt

Mounts a different filesystem volume on your account. Generally not used.

Arguments: a pathname to mount or system-specific string

Example code: 502

Example reply: SMNT not implemented.

=head3 mdtm

Gets the modification time of a file. Not supported by all servers! ( RFC 3659 )

Arguments: the file to query

Example code: 213

Example reply: 20110502230157

You can use the L<POE::Component::Client::SimpleFTP::Utils/mdtm_parser> function to convert it into a L<DateTime> object.

=head3 size

Gets the size of a file in bytes. Not supported by all servers! ( RFC 3659 )

Arguments: the file to query

Example code: 213

Example reply: 48

=head3 feat

Queries the FEAT capabilities of the server. Not supported by all servers! ( RFC 2389 )

Arguments: none

Example code: 211

Example reply:

	Features:
	EPRT
	EPSV
	MDTM
	PASV
	REST STREAM
	SIZE
	TVFS
	UTF8
	End

You can use the L<POE::Component::Client::SimpleFTP::Utils/feat_parser> function to convert it into an array of features.

=head3 features

An alias for L</feat>

=head3 opts

Sets an option for the current session. Not supported by all servers! ( RFC 2389 )

Arguments: the option to set

Example code: 501

Example reply: Option not understood.

=head3 options

An alias for L</opts>

=head2 Complex Commands

This class of commands is called complex because they require opening a new data connection to the server. The requested data is transferred
over this connection, and the result is sent back to your session. All of the commands behave the same except for the "upload" types.

Please look at the C<examples> directory included in this distribution for code samples.

The typical flow of this command is as follows:

	$ftp->yield( 'get', "/myfile.txt" );

	# receive a "get_connected" event
	#	args is: "/myfile.txt"

	# at this point you prepare to process the incoming data

	# receive a "get_data" event
	#	args is: $chunk, "/myfile.txt"

	# at this point you should write out the data to the terminal, a file, or whatever!

	# ... keep receiving "get_data" until the server finish sending

	# receive a "get" event
	#	args is: $code, $reply, "/myfile.txt"

	# at this point the transfer is complete

	# if at any point there is an error, a "get_error" event is sent
	#	args is: $code, $reply, "/myfile.txt"

For the "upload" events where you are sending data to the server, the flow is:

	$ftp->yield( 'put', '/myfile.txt' );

	# receive a "put_connected" event
	#	args is: "/myfile"

	# at this point you should get the data to send to the server
	# from your local filesystem, from a database server, or whatever!

	# send a chunk of data to the server
	# the chunk size should depend on your application - a reasonable default is 10240 bytes
	$ftp->yield( 'put_data', $chunk );

	# receive a "put_flushed" event
	#	args is: "/myfile"

	# at this point, you can either send another chunk or signal EOF
	$ftp->yield( 'put_close' );

	# receive a "put" event
	#	args is: $code, $reply, "/myfile"

	# at this point the transfer is complete

	# if at any point there is an error, a "put_error" event is sent
	#	args is: $code, $reply, "/myfile"

=head3 list

Receives a directory list. The data is sent in a format similar to the UNIX "ls" command, but can be anything!

Arguments: the optional path to query ( defaults to current working directory )

Example data:

	drwxr-xr-x    4 1000     1000         4096 May 02 18:24 a
	drwxr-xr-x    4 1000     1000         4096 May 02 18:24 b
	drwxr-xr-x    4 1000     1000         4096 May 02 18:24 c
	-rw-r--r--    1 1000     1000            0 May 02 20:26 foo.txt

=head3 ls

An alias for L<list>

=head3 nlst

Receives a directory list. Differs from L<list> in that only the names are received.

Arguments: the optional path to query ( defaults to current working directory )

Example data:

	a
	b
	c
	foo.txt

=head3 dir

An alias for L</nlst>

=head3 retr

Retrieves a file from the server.

Arguments: the filename to receive

=head3 get

An alias for L</get>

=head3 stor

Transmits a file to the server. This uses the "upload" command flow explained in L</Complex Commands>!

Arguments: the filename to put

=head3 stou

Transmits a file to the server. This differs from L</stor> in that the ftp server is required to store the file in a unique way. This uses the
"upload" command flow explained in L</Complex Commands>!

Arguments: the filename to put

=head3 put

An alias for L</stor>

=head1 ATTRIBUTES

=head2 alias

The alias this component will use. You can send commands to the ftpd in 2 ways:

	my $ftp = POE::Component::Client::SimpleFTP->new( alias => "ftp", ... );
	$poe_kernel->post( 'ftp', 'cd', 'foobar' );

	# Or, you can use the yield sub:
	$ftp->yield( 'cd', 'foobar' );

The default is: ftp

=head2 username

The FTP username you will be sending to the server.

required.

=head2 password

The FTP password you will be sending to the server.

required.

=head2 remote_addr

The IP address of the FTP server to connect to. Can be a DNS hostname or IPv4/6 string.

required.

=head2 remote_port

The port of the FTP server to connect to.

The default is: 21

=head2 local_addr

The local IP address to bind to for all connections to the server.

The default is: INADDR_ANY ( let the OS decide )

=head2 local_port

The local port to bind to for the control connection to the server. If you need to change the data connection's port, please
change the L</local_data_port> attribute.

The default is: 0 ( let the OS decide )

=head2 local_data_port

The local port to bind to for the data connection to the server. Must be a different port than the L</local_port> attribute!

The default is: 0 ( let the OS decide )

=head2 tls_cmd

A boolean value to enable/disable TLS encryption of the command connection. If you want to use this,
you must have L<POE::Component::SSLify> installed!

The default is: false

=head2 tls_data

A boolean value to enable/disable TLS encryption of the data connection. If you want to use this,
you must have L<POE::Component::SSLify> installed!

The default is: false

=head2 timeout

A value specifying the timeout in seconds for the initial connection to the FTP server.

The default is: 120

=head2 connection_mode

Determine what connection mode we will be using when opening the data connection to the server. In "active" mode,
the server will be connecting to us. In "passive" mode we will be connecting to the server. You usually need "passive" mode
if you are behind a firewall.

The default is: passive

=head1 METHODS

=head2 yield

This method provides an alternative object based means of posting events to the component.
First argument is the event to post, following arguments are sent as arguments to the resultant post.

	my $ftp = POE::Component::Client::SimpleFTP->new( alias => "ftp", ... );
	$ftp->yield( 'cd', 'foobar' );

	# equivalent to:
	$poe_kernel->post( $ftp->alias, 'cd', 'foobar' );

=head1 FUNCTIONS

=head2 DEBUG

Enable this if you want to get debugging output. Do it like this:

	sub POE::Component::Client::SimpleFTP::DEBUG () { 1 }
	use POE::Component::Client::SimpleFTP;

The default is: false

=head1 TLS support

TLS encryption is available if you want. You would need to enable the L</tls_cmd> and L</tls_data> attributes and have L<POE::Component::SSLify>
installed in order to use it. It should work with a lot of servers and commands. However, not the entire specification is implemented!
If you encounter problems when using TLS on a server, please let me know by filing a bug report!

=head1 Unimplemented Commands/Actions/Features

Those are the ideas that probably will be implemented in a future version. Some of them require core changes to this module, while others
can be done in user-space but should be implemented here to make it "simpler" :)

	* full TLS support - check the RFCs
	* FXP ( server<->server ) transfers
	* intelligent NAT detection
	* full ipv6 compatibility
	* restart/abort/append a transfer
	* bandwidth throttling for data connection
	* support for "mkdir -p" where this module automatically creates all directories needed
	* passing a filename/filehandle/whatever to put/get so this module automatically does the reading/writing
	* directory mirroring ( ala rsync )
	* use POE::Filter::Ls for parsing ( need to improve it first hah )
	* encoded pathnames ( translate \012 in filename to \000 as per RFC 959 )
	* security stuff - http://cr.yp.to/ftp/security.html
	* event prefix ( so you get ftp_cd events instead of cd ) for easier event management
	* strict command validation ( we don't check if the command requires 0, 1, or N args )

=head2 RFC 959 "FILE TRANSFER PROTOCOL (FTP)"

	* REIN ( not allowed, as it generally screws up - just reconnect! )
	* STRU ( default file type is always a good idea )
	* MODE ( default stream type is always a good idea )
	* APPE ( should be easy to implement, but im lazy )
	* ALLO ( it is generally unused and obsolete? )
	* REST ( a bit tricky to implement, maybe later )
	* ABOR ( not allowed, as it generally screws up - just disconnect! )
	* PASV ( this module automatically does it )
	* PORT ( this module automatically does it )
	* TYPE ( this module automatically does it )
	* STAT ( implemented, but not allowed while a transfer is in progress as it generally screws things up )

=head2 RFC 2228 "FTP Security Extensions"

	* AUTH ( only AUTH TLS is supported now )
	* PROT/PBSZ is supported with the default options if you enable tls_cmd/tls_data
	* ADAT ( not needed for AUTH TLS? )
	* CCC ( not needed with TLS? )
	* MIC ( not needed with TLS? )
	* CONF ( not needed with TLS? )
	* ENC ( not needed with TLS? )

=head2 RFC 2389 "Feature negotiation mechanism for the File Transfer Protocol"

	* The entire RFC is implemented

=head2 RFC 2428 "FTP Extensions for IPv6 and NATs"

	* EPRT
	* EPSV

=head2 RFC 2577 "FTP Security Considerations"

	* unimplemented

=head2 RFC 2640 "Internationalization of the File Transfer Protocol"

	* unimplemented

=head2 RFC 3659 "Extensions to FTP"

	* REST ( same reason as the RFC 959 one )
	* MLST
	* MLSD

=head2 RFC 4217 "Securing FTP with TLS"

	* unimplemented except for what is implemented in 2228 :)

=head2 RFC 5796 "FTP Command and Extension Registry"

	* No need to implement this, it is for servers only

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc POE::Component::Client::SimpleFTP

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/POE-Component-Client-SimpleFTP>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/POE-Component-Client-SimpleFTP>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-Client-SimpleFTP>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/POE-Component-Client-SimpleFTP>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/POE-Component-Client-SimpleFTP>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/POE-Component-Client-SimpleFTP>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/overview/POE-Component-Client-SimpleFTP>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/P/POE-Component-Client-SimpleFTP>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=POE-Component-Client-SimpleFTP>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=POE::Component::Client::SimpleFTP>

=back

=head2 Email

You can email the author of this module at C<APOCAL at cpan.org> asking for help with any problems you have.

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and join this channel: #perl-help then talk to this person for help: Apocalypse.

=item *

irc.freenode.net

You can connect to the server at 'irc.freenode.net' and join this channel: #perl then talk to this person for help: Apocal.

=item *

irc.efnet.org

You can connect to the server at 'irc.efnet.org' and join this channel: #perl then talk to this person for help: Ap0cal.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-poe-component-client-simpleftp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-Client-SimpleFTP>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/apocalypse/perl-poe-component-simpleftp>

  git clone https://github.com/apocalypse/perl-poe-component-simpleftp.git

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Apocalypse.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=head1 DISCLAIMER OF WARRANTY

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
