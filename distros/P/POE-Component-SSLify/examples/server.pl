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
use POE::Component::SSLify qw( Server_SSLify SSLify_Options SSLify_GetCipher SSLify_GetSocket );
use POE::Wheel::ReadWrite;
use POE::Wheel::SocketFactory;
use POE::Driver::SysRW;
use POE::Filter::Line;

POE::Session->create(
	'inline_states'	=>	{
		'_start'	=>	sub {
			# Okay, set the SSL certificate info
			eval {
				SSLify_Options( 'mylib/example.key', 'mylib/example.crt' );
			};
			SSLify_Options( '../mylib/example.key', '../mylib/example.crt' ) if ( $@ );

			# Set the alias
			$_[KERNEL]->alias_set( 'main' );

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

			# SSLify it!
			$socket = Server_SSLify( $socket );

			# testing stuff
			warn "got connection from: " . inet_ntoa( ( unpack_sockaddr_in( getpeername( SSLify_GetSocket( $socket ) ) ) )[1] ) . " cipher type: " . SSLify_GetCipher( $socket ) . "\n";

			# Hand it off to ReadWrite
			my $wheel = POE::Wheel::ReadWrite->new(
				'Handle'	=>	$socket,
				'Driver'	=>	POE::Driver::SysRW->new(),
				'Filter'	=>	POE::Filter::Line->new(),
				'InputEvent'	=>	'Got_Input',
				'FlushedEvent'	=>	'Got_Flush',
				'ErrorEvent'	=>	'Got_Error',
			);

			# Store it...
			$_[HEAP]->{'WHEELS'}->{ $wheel->ID } = $wheel;
			return 1;
		},
		'ListenerError'	=>	sub {
			# ARG0 = operation, ARG1 = error number, ARG2 = error string, ARG3 = wheel ID
			my ( $operation, $errnum, $errstr, $wheel_id ) = @_[ ARG0 .. ARG3 ];
			warn "SocketFactory Wheel $wheel_id generated $operation error $errnum: $errstr\n";

			return 1;
		},
		'Got_Input'	=>	sub {
			# ARG0: The Line, ARG1: Wheel ID

			# testing stuff
			my $socket = $_[HEAP]->{'WHEELS'}->{ $_[ARG1] }->get_output_handle();
			warn "got input from: " . inet_ntoa( ( unpack_sockaddr_in( getpeername( SSLify_GetSocket( $socket ) ) ) )[1] ) . " cipher type: (" . SSLify_GetCipher( $socket ) . ") input: '$_[ARG0]'\n";

			# Send back to the client the line!
			$_[HEAP]->{'WHEELS'}->{ $_[ARG1] }->put( $_[ARG0] );
			return 1;
		},
		'Got_Flush'	=>	sub {
			# We don't care about this event
			return 1;
		},
		'Got_Error'	=>	sub {
			# ARG0 = operation, ARG1 = error number, ARG2 = error string, ARG3 = wheel ID
			my ( $operation, $errnum, $errstr, $id ) = @_[ ARG0 .. ARG3 ];
			warn "Wheel $id generated $operation error $errnum: $errstr\n";

			# Done with a wheel
			delete $_[HEAP]->{'WHEELS'}->{ $_[ARG0] };
			return 1;
		},
	},
);

# Start POE!
POE::Kernel->run();
exit 0;
