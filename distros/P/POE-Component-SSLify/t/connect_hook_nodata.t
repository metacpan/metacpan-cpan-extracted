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
use strict; use warnings;

# This tests the connection OK hook on both server/client

use Test::FailWarnings;
use Test::More 1.001002; # new enough for sanity in done_testing()

use POE 1.267;
use POE::Component::Client::TCP;
use POE::Component::Server::TCP;
use POE::Component::SSLify qw/Client_SSLify Server_SSLify SSLify_Options SSLify_GetCipher SSLify_GetSocket SSLify_GetStatus/;

# TODO rewrite this to use Test::POE::Server::TCP and stuff :)

my $port;

POE::Component::Server::TCP->new
(
	Alias			=> 'myserver',
	Address			=> '127.0.0.1',
	Port			=> 0,

	Started			=> sub
	{
		use Socket qw/sockaddr_in/;
		$port = (sockaddr_in($_[HEAP]->{listener}->getsockname))[0];
	},
	ClientConnected		=> sub
	{
		ok(1, 'SERVER: accepted');
	},
	ClientDisconnected	=> sub
	{
		ok(1, 'SERVER: client disconnected');
		$_[KERNEL]->post( 'myserver' => 'shutdown');
	},
	ClientPreConnect	=> sub
	{
		eval { SSLify_Options('mylib/example.key', 'mylib/example.crt') };
		eval { SSLify_Options('../mylib/example.key', '../mylib/example.crt') } if ($@);
		ok(!$@, "SERVER: SSLify_Options $@");

		my $socket = eval { Server_SSLify( $_[ARG0], sub {
			my( $socket, $status, $errval ) = @_;

			pass( "SERVER: Got callback hook" );
			is( $status, 1, "SERVER: Status received from callback is OK" );

			## At this point, connection MUST be encrypted.
			my $cipher = SSLify_GetCipher($socket);
			ok($cipher ne '(NONE)', "SERVER: SSLify_GetCipher: $cipher");
			ok( SSLify_GetStatus($socket) == 1, "SERVER: SSLify_GetStatus is done" );
		} ) };
		ok(!$@, "SERVER: Server_SSLify $@");
		ok( SSLify_GetStatus($socket) == -1, "SERVER: SSLify_GetStatus is pending" );

		return ($socket);
	},
	ClientInput		=> sub
	{
		my ($kernel, $heap, $line) = @_[KERNEL, HEAP, ARG0];

		die "Should have never got any input from the client!";
	},
	ClientError	=> sub
	{
		# Thanks to H. Merijn Brand for spotting this FAIL in 5.12.0!
		# The default PoCo::Server::TCP handler will throw a warning, which causes Test::NoWarnings to FAIL :(
		my ($syscall, $errno, $error) = @_[ ARG0..ARG2 ];

		# TODO are there other "errors" that is harmless?
		$error = "Normal disconnection" unless $error;
		my $msg = "Got SERVER $syscall error $errno: $error";
		unless ( $syscall eq 'read' and $errno == 0 ) {
			fail( $msg );
		} else {
			diag( $msg ) if $ENV{TEST_VERBOSE};
		}
	},
);

POE::Component::Client::TCP->new
(
	Alias		=> 'myclient',
	RemoteAddress	=> '127.0.0.1',
	RemotePort	=> $port,

	Connected	=> sub
	{
		ok(1, 'CLIENT: connected');
	},
	PreConnect	=> sub
	{
		my $socket = eval { Client_SSLify($_[ARG0], sub {
			my( $socket, $status, $errval ) = @_;

			pass( "CLIENT: Got callback hook" );
			is( $status, 1, "CLIENT: Status received from callback is OK" );

			## At this point, connection MUST be encrypted.
			my $cipher = SSLify_GetCipher($socket);
			ok($cipher ne '(NONE)', "CLIENT: SSLify_GetCipher: $cipher");
			ok( SSLify_GetStatus($socket) == 1, "CLIENT: SSLify_GetStatus is done" );

			$poe_kernel->post( 'myclient' => 'shutdown' );
		}) };
		ok(!$@, "CLIENT: Client_SSLify $@");
		ok( SSLify_GetStatus($socket) == -1, "CLIENT: SSLify_GetStatus is pending" );

		return ($socket);
	},
	ServerInput	=> sub
	{
		my ($kernel, $heap, $line) = @_[KERNEL, HEAP, ARG0];

		die "Should have never got any input from the server!";
	},
	ServerError	=> sub
	{
		# Thanks to H. Merijn Brand for spotting this FAIL in 5.12.0!
		# The default PoCo::Client::TCP handler will throw a warning, which causes Test::NoWarnings to FAIL :(
		my ($syscall, $errno, $error) = @_[ ARG0..ARG2 ];

		# TODO are there other "errors" that is harmless?
		$error = "Normal disconnection" unless $error;
		my $msg = "Got CLIENT $syscall error $errno: $error";
		unless ( $syscall eq 'read' and $errno == 0 ) {
			fail( $msg );
		} else {
			diag( $msg ) if $ENV{TEST_VERBOSE};
		}
	},
);

$poe_kernel->run();

done_testing;
