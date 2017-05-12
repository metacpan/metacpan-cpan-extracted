#!/usr/bin/perl
#
# This file is part of POE-Component-SSLify
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;

use POE;
use Socket qw( inet_ntoa unpack_sockaddr_in );
use POE::Component::SSLify qw( Client_SSLify Server_SSLify SSLify_Options SSLify_GetCipher SSLify_GetSocket );
use POE::Wheel::ReadWrite;
use POE::Wheel::SocketFactory;
use POE::Driver::SysRW;
use POE::Filter::Line;
use POE::Wheel::ReadLine;

# create the server
POE::Session->create(
	'inline_states'	=>	{
		'_start'	=>	sub {
			# Okay, set the SSL certificate info
			eval {
				SSLify_Options( 'mylib/example.key', 'mylib/example.crt' );
			};
			SSLify_Options( '../mylib/example.key', '../mylib/example.crt' ) if ( $@ );

			# Set the alias
			$_[KERNEL]->alias_set( 'server' );

			# Create the socketfactory wheel to listen for requests
			$_[HEAP]->{'SOCKETFACTORY'} = POE::Wheel::SocketFactory->new(
				'BindPort'	=>	9898,
				'BindAddress'	=>	'localhost',
				'Reuse'		=>	'yes',
				'SuccessEvent'	=>	'Got_Connection',
				'FailureEvent'	=>	'ListenerError',
			);
			return 1;
		},
		'Got_Connection'	=>	sub {
			# ARG0 = Socket, ARG1 = Remote Address, ARG2 = Remote Port
			my $socket = $_[ ARG0 ];

			# testing stuff
			warn "got connection from: " . inet_ntoa( ( unpack_sockaddr_in( getpeername( $socket ) ) )[1] ) . " - commencing Server_SSLify()\n";

			# SSLify it!
			$socket = Server_SSLify( $socket );

			# testing stuff
			warn "SSLified: " . inet_ntoa( ( unpack_sockaddr_in( getpeername( SSLify_GetSocket( $socket ) ) ) )[1] ) . " cipher type: (" . SSLify_GetCipher( $socket ) . ")\n";

			# Hand it off to ReadWrite
			my $wheel = POE::Wheel::ReadWrite->new(
				'Handle'	=>	$socket,
				'Driver'	=>	POE::Driver::SysRW->new(),
				'Filter'	=>	POE::Filter::Line->new(),
				'InputEvent'	=>	'Got_Input',
				'ErrorEvent'	=>	'Got_Error',
			);

			# Store it...
			$_[HEAP]->{'WHEELS'}->{ $wheel->ID } = $wheel;
			return;
		},
		'ListenerError'	=>	sub {
			# ARG0 = operation, ARG1 = error number, ARG2 = error string, ARG3 = wheel ID
			my ( $operation, $errnum, $errstr, $wheel_id ) = @_[ ARG0 .. ARG3 ];
			warn "SocketFactory Wheel $wheel_id generated $operation error $errnum: $errstr\n";

			return;
		},
		'Got_Input'	=>	sub {
			# ARG0: The Line, ARG1: Wheel ID

			# testing stuff
			my $socket = $_[HEAP]->{'WHEELS'}->{ $_[ARG1] }->get_output_handle();
			warn "got input from: " . inet_ntoa( ( unpack_sockaddr_in( getpeername( SSLify_GetSocket( $socket ) ) ) )[1] ) . " cipher type: (" . SSLify_GetCipher( $socket ) . ") input: '$_[ARG0]'\n";

			# Send back to the client the line!
			$_[HEAP]->{'WHEELS'}->{ $_[ARG1] }->put( $_[ARG0] );
			return;
		},
		'Got_Error'	=>	sub {
			# ARG0 = operation, ARG1 = error number, ARG2 = error string, ARG3 = wheel ID
			my ( $operation, $errnum, $errstr, $id ) = @_[ ARG0 .. ARG3 ];
			warn "Wheel $id generated $operation error $errnum: $errstr\n";

			# Done with a wheel
			delete $_[HEAP]->{'WHEELS'}->{ $_[ARG0] };
			return;
		},
	},
);

# create the client
POE::Session->create(
	'inline_states'	=>	{
		'_start'	=>	sub {
			# Set the alias
			$_[KERNEL]->alias_set( 'client' );

			# Setup our ReadLine stuff
			$_[HEAP]->{'RL'} = POE::Wheel::ReadLine->new(
				'InputEvent'	=> 'Got_ReadLine',
			);

			# Connect to the server!
			$_[KERNEL]->yield( 'do_connect' );
			return;
		},
		'do_connect'		=>	sub {
			# Create the socketfactory wheel to listen for requests
			$_[HEAP]->{'SOCKETFACTORY'} = POE::Wheel::SocketFactory->new(
				'RemotePort'	=>	9898,
				'RemoteAddress'	=>	'localhost',
				'Reuse'		=>	'yes',
				'SuccessEvent'	=>	'Got_Connection',
				'FailureEvent'	=>	'ConnectError',
			);
			return;
		},
		'Got_ReadLine'		=>	sub {
			if ( defined $_[ARG0] ) {
				if ( exists $_[HEAP]->{'WHEEL'} ) {
					$_[HEAP]->{'WHEEL'}->put( $_[ARG0] );
				}
			} else {
				if ( $_[ARG1] eq 'interrupt' ) {
					die 'stopped';
				}
			}
			return;
		},
		'Got_Connection'	=>	sub {
			# ARG0 = Socket, ARG1 = Remote Address, ARG2 = Remote Port
			my $socket = $_[ ARG0 ];

			warn "Connected to server, commencing Client_SSLify()\n";

			# SSLify it!
			$socket = Client_SSLify( $socket );

			warn "SSLified the connection to the server\n";

			# Hand it off to ReadWrite
			my $wheel = POE::Wheel::ReadWrite->new(
				'Handle'	=>	$socket,
				'Driver'	=>	POE::Driver::SysRW->new(),
				'Filter'	=>	POE::Filter::Line->new(),
				'InputEvent'	=>	'Got_Input',
				'ErrorEvent'	=>	'Got_Error',
			);

			# Store it...
			$_[HEAP]->{'WHEEL'} = $wheel;
			$_[HEAP]->{'RL'}->put( 'Connected to SSL server' );
			$_[HEAP]->{'RL'}->get( 'Input: ' );

			return;
		},
		'ConnectError'	=>	sub {
			# ARG0 = operation, ARG1 = error number, ARG2 = error string, ARG3 = wheel ID
			my ( $operation, $errnum, $errstr, $wheel_id ) = @_[ ARG0 .. ARG3 ];
			warn "SocketFactory Wheel $wheel_id generated $operation error $errnum: $errstr\n";
			delete $_[HEAP]->{'SOCKETFACTORY'};
			$_[HEAP]->{'RL'}->put( 'Unable to connect to SSL server...' );
			$_[KERNEL]->delay_set( 'do_connect', 5 );
			return;
		},
		'Got_Input'	=>	sub {
			# ARG0: The Line, ARG1: Wheel ID

			# Send back to the client the line!
			$_[HEAP]->{'RL'}->put( 'Got Reply: ' . $_[ARG0] );
			$_[HEAP]->{'RL'}->get( 'Input: ' );
			return;
		},
		'Got_Error'	=>	sub {
			# ARG0 = operation, ARG1 = error number, ARG2 = error string, ARG3 = wheel ID
			my ( $operation, $errnum, $errstr, $id ) = @_[ ARG0 .. ARG3 ];
			warn "Wheel $id generated $operation error $errnum: $errstr\n";
			delete $_[HEAP]->{'WHEEL'};
			$_[HEAP]->{'RL'}->put( 'Disconnected from SSL server...' );
			$_[KERNEL]->delay_set( 'do_connect', 5 );
			return;
		},
	},
);

# Start POE!
POE::Kernel->run();
exit 0;
