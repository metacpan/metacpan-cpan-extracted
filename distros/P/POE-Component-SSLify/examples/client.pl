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
use POE::Component::SSLify qw( Client_SSLify );
use POE::Wheel::ReadWrite;
use POE::Wheel::SocketFactory;
use POE::Driver::SysRW;
use POE::Filter::Line;
use POE::Wheel::ReadLine;

POE::Session->create(
	'inline_states'	=>	{
		'_start'	=>	sub {
			# Set the alias
			$_[KERNEL]->alias_set( 'main' );

			# Setup our ReadLine stuff
			$_[HEAP]->{'RL'} = POE::Wheel::ReadLine->new(
				'InputEvent'	=> 'Got_ReadLine',
			);

			# Connect to the server!
			$_[KERNEL]->yield( 'do_connect' );
			return 1;
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
			return 1;
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
		},
		'Got_Connection'	=>	sub {
			# ARG0 = Socket, ARG1 = Remote Address, ARG2 = Remote Port
			my $socket = $_[ ARG0 ];

			# SSLify it!
			$socket = Client_SSLify( $socket );

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

			return 1;
		},
		'ConnectError'	=>	sub {
			# ARG0 = operation, ARG1 = error number, ARG2 = error string, ARG3 = wheel ID
			my ( $operation, $errnum, $errstr, $wheel_id ) = @_[ ARG0 .. ARG3 ];
			warn "SocketFactory Wheel $wheel_id generated $operation error $errnum: $errstr\n";
			delete $_[HEAP]->{'SOCKETFACTORY'};
			$_[HEAP]->{'RL'}->put( 'Unable to connect to SSL server...' );
			$_[KERNEL]->delay_set( 'do_connect', 5 );
			return 1;
		},
		'Got_Input'	=>	sub {
			# ARG0: The Line, ARG1: Wheel ID

			# Send back to the client the line!
			$_[HEAP]->{'RL'}->put( 'Got Reply: ' . $_[ARG0] );
			$_[HEAP]->{'RL'}->get( 'Input: ' );
			return 1;
		},
		'Got_Error'	=>	sub {
			# ARG0 = operation, ARG1 = error number, ARG2 = error string, ARG3 = wheel ID
			my ( $operation, $errnum, $errstr, $id ) = @_[ ARG0 .. ARG3 ];
			warn "Wheel $id generated $operation error $errnum: $errstr\n";
			delete $_[HEAP]->{'WHEEL'};
			$_[HEAP]->{'RL'}->put( 'Disconnected from SSL server...' );
			$_[KERNEL]->delay_set( 'do_connect', 5 );
			return 1;
		},
	},
);

# Start POE!
POE::Kernel->run();
exit 0;
