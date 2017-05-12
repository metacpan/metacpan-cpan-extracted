# Declare our package
package POE::Component::Lightspeed::Client;

# Standard stuff to catch errors
use strict qw(subs vars refs);				# Make sure we can't mess up
use warnings FATAL => 'all';				# Enable warnings to catch errors

# Initialize our version
our $VERSION = '1.' . sprintf( "%04d", (qw($Revision: 1082 $))[1] );

# Import what we need
use Carp qw( croak );
use Time::HiRes qw( gettimeofday );
use POE;
use POE::Wheel::SocketFactory;
use POE::Wheel::ReadWrite;
use POE::Driver::SysRW;
use POE::Filter::Line;
use POE::Filter::Reference;
use POE::Component::Lightspeed::Router;
use POE::Component::Lightspeed::Constants qw( MSG_TIMESTAMP MSG_ACTION );

# Set some constants
BEGIN {
	# Debug fun!
	if ( ! defined &DEBUG ) {
		eval "sub DEBUG () { 0 }";
	}
}

# Spawn the Router session
POE::Component::Lightspeed::Router->spawn();

# Spawns an instance of the client
sub spawn {
	# Get the OOP's type
	my $type = shift;

	# Sanity checking
	if ( @_ & 1 ) {
		croak( 'POE::Component::Lightspeed::Client->spawn needs even number of options' );
	}

	# The options hash
	my %opt = @_;

	# Our own options
	my ( $ALIAS, $KERNEL, $ADDRESS, $PORT, $SERIALIZERS, $COMPRESSION, $USESSL, $PASSWORD );

	# Get the session alias
	if ( exists $opt{'ALIAS'} and defined $opt{'ALIAS'} and length( $opt{'ALIAS'} ) ) {
		$ALIAS = delete $opt{'ALIAS'};
	} else {
		# Debugging info...
		if ( DEBUG ) {
			warn 'Using default ALIAS = lightspeed_client';
		}

		# Set the default
		$ALIAS = 'lightspeed_client';

		# Remove any lingering ALIAS
		if ( exists $opt{'ALIAS'} ) {
			delete $opt{'ALIAS'};
		}
	}

	# Get the KERNEL
	if ( exists $opt{'KERNEL'} and defined $opt{'KERNEL'} and length( $opt{'KERNEL'} ) ) {
		$KERNEL = delete $opt{'KERNEL'};
	} else {
		# Debugging info...
		if ( DEBUG ) {
			warn 'Using default KERNEL = Supplied by POE';
		}

		# Set the default
		$KERNEL = $poe_kernel->ID;

		if ( exists $opt{'KERNEL'} ) {
			delete $opt{'KERNEL'};
		}
	}

	# Get the ADDRESS
	if ( exists $opt{'ADDRESS'} and defined $opt{'ADDRESS'} and length( $opt{'ADDRESS'} ) ) {
		$ADDRESS = delete $opt{'ADDRESS'};
	} else {
		warn 'POE::Component::Lightspeed::Server->spawn must get at least 1 argument - the address to connect!';
		return undef;
	}

	# Get the PORT
	if ( exists $opt{'PORT'} and defined $opt{'PORT'} and length( $opt{'PORT'} ) ) {
		$PORT = delete $opt{'PORT'};
	} else {
		# Debugging info...
		if ( DEBUG ) {
			warn 'Using default PORT = 9876';
		}

		# Set the default
		$PORT = 9876;

		if ( exists $opt{'PORT'} ) {
			delete $opt{'PORT'};
		}
	}

	# Get the SERIALIZERS
	if ( exists $opt{'SERIALIZERS'} and defined $opt{'SERIALIZERS'} and ref( $opt{'SERIALIZERS'} ) and ref( $opt{'SERIALIZERS'} ) eq 'ARRAY' ) {
		$SERIALIZERS = delete $opt{'SERIALIZERS'};
	} else {
		# Debugging info...
		if ( DEBUG ) {
			warn 'Using default SERIALIZERS = Storable, YAML';
		}

		# Set the default
		$SERIALIZERS = [ 'Storable', 'YAML' ];

		if ( exists $opt{'SERIALIZERS'} ) {
			delete $opt{'SERIALIZERS'};
		}
	}

	# Get the COMPRESSION
	if ( exists $opt{'COMPRESSION'} and defined $opt{'COMPRESSION'} and length( $opt{'COMPRESSION'} ) ) {
		$COMPRESSION = delete $opt{'COMPRESSION'};
	} else {
		# Debugging info...
		if ( DEBUG ) {
			warn 'Using default COMPRESSION = false';
		}

		# Set the default
		$COMPRESSION = 0;

		if ( exists $opt{'COMPRESSION'} ) {
			delete $opt{'COMPRESSION'};
		}
	}

	# Get the USESSL
	if ( exists $opt{'USESSL'} and defined $opt{'USESSL'} and length( $opt{'USESSL'} ) ) {
		$USESSL = delete $opt{'USESSL'};

		# Check if we want it
		if ( $USESSL ) {
			eval {
				use POE::Component::SSLify qw( Client_SSLify );
			};

			# Error-checking
			if ( $@ ) {
				warn "Unable to load SSLify: $@";
				$USESSL = 0;
			}
		}
	} else {
		# Debugging info...
		if ( DEBUG ) {
			warn 'Using default USESSL = false';
		}

		# Set the default
		$USESSL = 0;

		if ( exists $opt{'USESSL'} ) {
			delete $opt{'USESSL'};
		}
	}

	# Get the PASSWORD
	if ( exists $opt{'PASSWORD'} and defined $opt{'PASSWORD'} and length( $opt{'PASSWORD'} ) ) {
		$PASSWORD = delete $opt{'PASSWORD'};
	} else {
		# Debugging info...
		if ( DEBUG ) {
			warn 'Using default PASSWORD = undef';
		}

		# Set the default
		$PASSWORD = undef;

		if ( exists $opt{'PASSWORD'} ) {
			delete $opt{'PASSWORD'};
		}
	}

	# Create the POE Session!
	POE::Session->create(
		'inline_states'	=>	{
			# Generic stuff
			'_start'		=>	\&StartClient,
			'_stop'			=>	sub {},

			# Public events
			'shutdown'		=>	\&StopClient,

			# SocketFactory events
			'CreateSF'		=>	\&Create_SocketFactory,
			'GotConnection'		=>	\&GotConnection,
			'SFError'		=>	\&SFError,

			# ReadWrite events
			'InputLine'		=>	\&InputLine,
			'InputHash'		=>	\&InputHash,
			'Flushed'		=>	sub {},
			'RWError'		=>	\&RWError,

			# Router events
			'send'			=>	\&Send_Packet,
			'killclient'		=>	\&StopClient,
		},

		# Our own heap
		'heap'		=>	{
			'ALIAS'		=>	$ALIAS,
			'MYKERNEL'	=>	$KERNEL,

			# Connection stuff
			'PHASE'		=>	'no',
			'SERIALIZER_C'	=>	0,
			'FILTER'	=>	undef,
			'WHEEL'		=>	undef,
			'SF'		=>	undef,

			# Packet statistics
			'PACKETS_IN'	=>	0,
			'PACKETS_OUT'	=>	0,

			# The server info
			'SERVER_IP'	=>	$ADDRESS,
			'SERVER_PORT'	=>	$PORT,
			'SERVER_VER'	=>	undef,
			'SERVER_KERNEL'	=>	undef,
			'SERIALIZER'	=>	$SERIALIZERS,
			'COMPRESSION'	=>	$COMPRESSION,
			'USESSL'	=>	$USESSL,
			'PASSWORD'	=>	$PASSWORD,
		},
	) or die 'Unable to create a new session!';

	# Return success
	return 1;
}

# Connects to a lightspeed server
sub StartClient {
	# Okay, can we take the alias?
	if ( ! $_[KERNEL]->_resolve_session( $_[HEAP]->{'ALIAS'} ) ) {
		# Set it!
		$_[KERNEL]->alias_set( $_[HEAP]->{'ALIAS'} );
	} else {
		# Loop over fake numbers
		my $num = 0;
		while ( ++$num ) {
			if ( ! $_[KERNEL]->_resolve_session( $_[HEAP]->{'ALIAS'} . '_' . $num ) ) {
				# Set this as our new alias
				$_[HEAP]->{'ALIAS'} = $_[HEAP]->{'ALIAS'} . '_' . $num;

				# Debug stuff
				if ( DEBUG ) {
					warn "Finally found an alias to use -> " . $_[HEAP]->{'ALIAS'};
				}

				# Actually set it!
				$_[KERNEL]->alias_set( $_[HEAP]->{'ALIAS'} );
				last;
			}
		}
	}

	# Create the wheel
	$_[KERNEL]->yield( 'CreateSF' );

	# All done!
	return 1;
}

# Shuts ourself down
sub StopClient {
	# ARG0 = wheel id but we don't care :)

	# Debug stuff
	if ( DEBUG ) {
		warn "Shutting down the client '$_[HEAP]->{'ALIAS'}'";
	}

	# Remove the alias
	$_[KERNEL]->alias_remove( $_[HEAP]->{'ALIAS'} );

	# If we received a packet, that means we've told the router we are connected
	# Also, if the wheel is still alive, that means somebody TOLD us to shutdown
	if ( $_[HEAP]->{'PACKETS_IN'} and defined $_[HEAP]->{'RW'} ) {
		# Let the router know the link is down
		$_[KERNEL]->call( $POE::Component::Lightspeed::Router::SES_ALIAS, 'link_down', $_[HEAP]->{'RW'}->ID );
	}

	# Remove any wheels
	undef $_[HEAP]->{'SF'};
	undef $_[HEAP]->{'RW'};

	# All done!
	return 1;
}

# Actually creates the SocketFactory wheel
sub Create_SocketFactory {
	# Okay, time to create the connection!
	$_[HEAP]->{'SF'} = POE::Wheel::SocketFactory->new(
		'RemotePort'	=>	$_[HEAP]->{'SERVER_PORT'},
		'RemoteAddress'	=>	$_[HEAP]->{'SERVER_IP'},
		'SuccessEvent'	=>	'GotConnection',
		'FailureEvent'	=>	'SFError',
	);

	# All done!
	return 1;
}

# We are connected to the server!
sub GotConnection {
	# ARG0 = Socket, ARG1 = Remote Address, ARG2 = Remote Port, ARG3 = wheelid
	my $socket = $_[ARG0];

	# Get rid of the SocketFactory
	undef $_[HEAP]->{'SF'};

	# Should we use SSL?
	if ( $_[HEAP]->{'USESSL'} ) {
		eval { $socket = Client_SSLify( $socket ); };

		# Error Checking
		if ( $@ ) {
			if ( DEBUG ) {
				warn "Unable to turn socket into SSL -> $@";
			}

			# Shutdown!
			$_[KERNEL]->call( $_[SESSION], 'shutdown' );
		}
	}

	# Set up the Wheel to read from the socket
	my $wheel = POE::Wheel::ReadWrite->new(
		'Handle'	=>	$socket,
		'Driver'	=>	POE::Driver::SysRW->new(),
		'Filter'	=>	POE::Filter::Line->new(),
		'InputEvent'	=>	'InputLine',
		'FlushedEvent'	=>	'Flushed',
		'ErrorEvent'	=>	'RWError',
	);

	# Save this wheel!
	$_[HEAP]->{'RW'} = $wheel;

	# Debug stuff
	if ( DEBUG ) {
		warn "GotConnection completed creation of ReadWrite wheel ( " . $wheel->ID . " )";
	}

	# Success!
	return 1;
}

# Got some sort of error from SocketFactory
sub SFError {
	# ARG0 = operation, ARG1 = error number, ARG2 = error string, ARG3 = wheel ID
	my ( $operation, $errnum, $errstr, $wheel_id ) = @_[ ARG0 .. ARG3 ];

	# Debug stuff
	if ( DEBUG ) {
		warn "SocketFactory Wheel $wheel_id generated $operation error $errnum: $errstr\n";
	}

	# Shutdown ourself
	$_[KERNEL]->yield( 'shutdown' );

	# Success!
	return 1;
}

# Helper sub to get the next serializer available
sub _Get_NextSerializer {
	# Get the heap
	my $h = shift;

	# Okay, generate the next one
	while ( 1 ) {
		# Reality check!
		if ( ! defined $h->{'SERIALIZER'}->[ $h->{'SERIALIZER_C'} ] ) {
			warn "Unable to find a working serializer!";

			# Close the connection, grudingly
			undef $h->{'RW'};

			# Tell ourself to shutdown
			$poe_kernel->yield( 'shutdown' );

			# All done
			return undef;
		}

		# Proceed with the next serializer we have
		my $filter = [ $h->{'SERIALIZER'}->[ $h->{'SERIALIZER_C'}++ ] ];
		eval { $filter->[1] = POE::Filter::Reference->new( $filter->[0], $h->{'COMPRESSION'} ); };

		if ( $@ ) {
			if ( DEBUG ) {
				warn "Serializer $filter->[0] failed to load!";
			}
			next;
		} else {
			$h->{'FILTER'} = $filter;
			return 1;
		}
	}
}

# Got some input!
sub InputLine {
	# ARG0 = input, ARG1 = wheel id
	my $line = $_[ARG0];

	# Skip empty lines
	return if $line eq '';

	# Did we get an error?
	if ( $line =~ /^ERROR/ ) {
		# Aw, dang!
		if ( DEBUG ) {
			warn "Got ERROR from server in the $_[HEAP]->{'PHASE'} phase -> $line";
		}

		# Get rid of ourself...
		$_[KERNEL]->call( $_[SESSION], 'shutdown' );
		return undef;
	}

	# Ok, what stage of negotiations are we on?
	if ( $_[HEAP]->{'PHASE'} eq 'no' ) {
		# Should be the welcome line
		if ( $line =~ /^SERVER\s+Lightspeed\s+v\/(.*)\s+kernel\s+(.*)$/ ) {
			# Okay, this server talks lightspeed :)
			$_[HEAP]->{'SERVER_VER'} = $1;
			$_[HEAP]->{'SERVER_KERNEL'} = $2;

			# Send the client stuff
			$_[HEAP]->{'RW'}->put( 'CLIENT Lightspeed v/' . $VERSION . ' kernel ' . $_[HEAP]->{'MYKERNEL'} );

			# Do we have a password?
			if ( defined $_[HEAP]->{'PASSWORD'} ) {
				$_[HEAP]->{'PHASE'} = 'password';

				# Send it off!
				$_[HEAP]->{'RW'}->put( 'PASSWORD ' . $_[HEAP]->{'PASSWORD'} );
			} else {
				$_[HEAP]->{'PHASE'} = 'compression';

				# Do we want compression?
				if ( $_[HEAP]->{'COMPRESSION'} ) {
					$_[HEAP]->{'RW'}->put( 'COMPRESSION ON' );
				} else {
					$_[HEAP]->{'RW'}->put( 'COMPRESSION OFF' );
				}
			}
		} else {
			# Doesn't talk lightspeed?
			if ( DEBUG ) {
				warn "Server doesn't talk Lightspeed -> input was: $line";
			}

			# Shutdown!
			$_[KERNEL]->call( $_[SESSION], 'shutdown' );
		}
	} elsif ( $_[HEAP]->{'PHASE'} eq 'password' ) {
		# Should be the password line
		if ( $line eq 'PASSWORD OK' ) {
			# Move on to the next phase
			$_[HEAP]->{'PHASE'} = 'compression';

			# Do we want compression?
			if ( $_[HEAP]->{'COMPRESSION'} ) {
				$_[HEAP]->{'RW'}->put( 'COMPRESSION ON' );
			} else {
				$_[HEAP]->{'RW'}->put( 'COMPRESSION OFF' );
			}
		} else {
			# Doesn't talk lightspeed?
			if ( DEBUG ) {
				warn "Server doesn't talk Lightspeed -> input was: $line";
			}

			# Shutdown!
			$_[KERNEL]->call( $_[SESSION], 'shutdown' );
		}
	} elsif ( $_[HEAP]->{'PHASE'} eq 'compression' ) {
		# Should be the compress line
		if ( $line eq 'COMPRESSION NOT OK' ) {
			# Server disagreed with our choice, dangit!
			if ( DEBUG ) {
				warn "Server didn't like our compression: $_[HEAP]->{'COMPRESSION'}";
			}

			# Shutdown!
			$_[KERNEL]->call( $_[SESSION], 'shutdown' );
		} else {
			# Move on to the next phase
			$_[HEAP]->{'PHASE'} = 'serializer';

			# Send the serializer line
			if ( _Get_NextSerializer( $_[HEAP] ) ) {
				$_[HEAP]->{'RW'}->put( 'SERIALIZER ' . $_[HEAP]->{'FILTER'}->[0] );
			} else {
				# Found no serializer, abort
				if ( DEBUG ) {
					warn "Exhausted our serializer options, no choice but to shut down";
				}

				# Shutdown!
				$_[KERNEL]->call( $_[SESSION], 'shutdown' );
			}
		}
	} elsif ( $_[HEAP]->{'PHASE'} eq 'serializer' ) {
		# Should be the serializer line
		if ( $line eq 'SERIALIZER OK' ) {
			# Yay, we are all done...
			$_[HEAP]->{'RW'}->put( 'DONE' );

			# We are connected!
			$_[HEAP]->{'PHASE'} = 'connected';

			# Change the filter
			$_[HEAP]->{'RW'}->set_filter( $_[HEAP]->{'FILTER'}->[1] );
			$_[HEAP]->{'RW'}->event( 'InputEvent', 'InputHash' );

			# Let the Router know a link is up
			$_[KERNEL]->call( $POE::Component::Lightspeed::Router::SES_ALIAS, 'link_up', $_[HEAP]->{'RW'}->ID, $_[HEAP]->{'MYKERNEL'}, $_[HEAP]->{'SERVER_KERNEL'}, 'Client' );
		} else {
			# Send the serializer line
			if ( _Get_NextSerializer( $_[HEAP] ) ) {
				$_[HEAP]->{'RW'}->put( 'SERIALIZER ' . $_[HEAP]->{'FILTER'}->[0] );
			} else {
				# Found no serializer, abort
				if ( DEBUG ) {
					warn "Exhausted our serializer options, no choice but to shut down";
				}

				# Shutdown!
				$_[KERNEL]->call( $_[SESSION], 'shutdown' );
			}
		}
	}

	# All done!
	return 1;
}

# The main method of communication
sub InputHash {
	# ARG0 = data, ARG1 = wheel id
	my( $msg, $id ) = @_[ ARG0, ARG1 ];

	if ( DEBUG ) {
		warn "Received packet from server $_[HEAP]->{'SERVER_IP'} - $_[HEAP]->{'SERVER_PORT'}:\n" . Data::Dumper::Dumper( $msg );
	}

	# Send it off to the Router!
	$_[KERNEL]->post( $POE::Component::Lightspeed::Router::SES_ALIAS, 'ACTION_' . $msg->[ MSG_ACTION ], $msg, $id );

	# Increment the packet count
	$_[HEAP]->{'PACKETS_IN'}++;

	# All done!
	return 1;
}

# ReadWrite error
sub RWError {
	# ARG0 = operation, ARG1 = error number, ARG2 = error string, ARG3 = wheel ID
	my ( $operation, $errnum, $errstr, $wheel_id ) = @_[ ARG0 .. ARG3 ];

	# Debug stuff
	if ( DEBUG ) {
		warn "ReadWrite Wheel $wheel_id generated $operation error $errnum: $errstr\n";
	}

	# Get rid of our RW wheel
	undef $_[HEAP]->{'RW'};

	# Let the router know the link is down
	if ( $_[HEAP]->{'PHASE'} eq 'connected' ) {
		$_[KERNEL]->call( $POE::Component::Lightspeed::Router::SES_ALIAS, 'link_down', $wheel_id );
	}

	# Shutdown ourself
	$_[KERNEL]->yield( 'shutdown' );

	# Success!
	return 1;
}

# Sends a packet down the wire
sub Send_Packet {
	# ARG0 = wheel id, ARG1 = packet
	my $packet = $_[ARG1];

	# Sanity check
	if ( ! defined $_[HEAP]->{'RW'} ) {
		if ( DEBUG ) {
			warn "Link is down, received a packet to send...";
		}
		return;
	}

	# Add the timestamp
	if ( ! defined $packet->[ MSG_TIMESTAMP ] ) {
		$packet->[ MSG_TIMESTAMP ] = gettimeofday();
	}

	if ( DEBUG ) {
		warn "Sending packet to server $_[HEAP]->{'SERVER_IP'} - $_[HEAP]->{'SERVER_PORT'}:\n" . Data::Dumper::Dumper( $packet );
	}

	# Send it...
	$_[HEAP]->{'RW'}->put( $packet );

	# Increment the packet count
	$_[HEAP]->{'PACKETS_OUT'}++;

	# All done!
	return 1;
}

# End of module
1;
__END__

=head1 NAME

POE::Component::Lightspeed::Client - Connects to Lightspeed servers

=head1 SYNOPSIS

	use POE;
	use POE::Component::Lightspeed::Client;

	POE::Component::Lightspeed::Client->spawn(
		'ALIAS'		=>	'myclient',
		'KERNEL'	=>	'mybox',
		'ADDRESS'	=>	'localhost',
		'PORT'		=>	5634,
		'SERIALIZERS'	=>	[ qw( MySerializer Storable ) ],
		'COMPRESSION'	=>	1,
	) or die "Unable to create Client session!";

	# Communicate with the rest of the network!

=head1 ABSTRACT

	The Lightspeed Client session

=head1 DESCRIPTION

This module connects to remote Lightspeed servers. Usage is exactly the same as described in the Lightspeed documentation.

=head2 Starting Lightspeed::Client

To start the client, just call it's spawn method:

	POE::Component::Server::SimpleHTTP->spawn(
		'ALIAS'		=>	'myclient',
		'KERNEL'	=>	'mybox',
		'ADDRESS'	=>	'localhost',
		'PORT'		=>	5634,
		'SERIALIZERS'	=>	[ qw( MySerializer Storable ) ],
		'COMPRESSION'	=>	1,
	) or die "Unable to create Client session!";

This method will return undef on error or return success.

This constructor accepts only 8 options.

=over 4

=item C<ADDRESS>

The address of the remote server.

This is the only MANDATORY argument.

=item C<ALIAS>

This will set the alias this client session uses in the POE Kernel.

This will default to "lightspeed_client" or "lightspeed_clientX" where x is a number sequence.

=item C<PORT>

The port of the remote server.

This will default to '9876'.

=item C<KERNEL>

The descriptive name of the local kernel.

This will default to $POE::Kernel::poe_kernel->ID().

=item C<SERIALIZERS>

This should be an arrayref of serializers to use

This will default to:
	[ qw( Storable YAML ) ]

=item C<COMPRESSION>

This is the boolean option passed to POE::Filter::Reference

This will default to false ( 0 )

=item C<USESSL>

This is a boolean option whether to turn on SSL encryption for the link.

This will default to false ( 0 )

=item C<PASSWORD>

The password for the server, if it requires one.

This will default to nothing.

=back

=head2 Usage

The Client session will connect to the remote kernel, and allow message-passing operations to begin.

It's pretty strict about the initial connection to the server, and will shutdown immediately if it finds any errors.

=head2 Commands

There's only one command you can send: the shutdown event.

Keep in mind that you need the alias of the session if you have several of them running!

$kernel->post( 'lightspeed_client', 'shutdown' );

=head2 Notes

This module is very picky about capitalization!

All of the options are uppercase, to avoid confusion.

You can enable debugging mode by doing this:

	sub POE::Component::Lightspeed::Client::DEBUG () { 1 }
	use POE::Component::Lightspeed::Client;

=head1 EXPORT

Nothing.

=head1 SEE ALSO

L<POE::Component::Lightspeed>

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
