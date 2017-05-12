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

# This is an extension of the simple_parallel.t test to test for large responses

use Test::FailWarnings;
use Test::More 1.001002; # new enough for sanity in done_testing()

use POE 1.267;
use POE::Component::Client::TCP;
use POE::Component::Server::TCP;
use POE::Component::SSLify qw/Client_SSLify Server_SSLify SSLify_Options SSLify_GetCipher SSLify_ContextCreate SSLify_GetSocket SSLify_GetSSL/;

# TODO rewrite this to use Test::POE::Server::TCP and stuff :)

my $port;
my $replies = 0;

my $bigpacket = join( '-', ('a' .. 'z') x 10000, ('A' .. 'Z') x 10000 ) x 2;

POE::Component::Server::TCP->new
(
	Alias			=> 'myserver',
	Address			=> '127.0.0.1',
	Port			=> 0,
	ClientFilter 		=> ['POE::Filter::Block', 'BlockSize' => length $bigpacket],
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
		$_[KERNEL]->post(myserver => 'shutdown') if $replies == 10;
	},
	ClientPreConnect	=> sub
	{
		eval { SSLify_Options('mylib/example.key', 'mylib/example.crt', 'sslv3') };
		eval { SSLify_Options('../mylib/example.key', '../mylib/example.crt', 'sslv3') } if ($@);
		ok(!$@, "SERVER: SSLify_Options $@");

		my $socket = eval { Server_SSLify($_[ARG0]) };
		ok(!$@, "SERVER: Server_SSLify $@");
		ok(1, 'SERVER: SSLify_GetCipher: '. SSLify_GetCipher($socket));

		# We pray that IO::Handle is sane...
		ok( SSLify_GetSocket( $socket )->blocking == 0, 'SERVER: SSLified socket is non-blocking?') if $^O ne 'MSWin32';

		return ($socket);
	},
	ClientInput		=> sub
	{
		my ($kernel, $heap, $line) = @_[KERNEL, HEAP, ARG0];

		if ( $line eq $bigpacket ) {
			## At this point, connection MUST be encrypted.
			my $cipher = SSLify_GetCipher($heap->{client}->get_output_handle);
			ok($cipher ne '(NONE)', "SERVER: SSLify_GetCipher: $cipher");

			$heap->{client}->put($bigpacket);
		} else {
			die "Unknown line from CLIENT: $line";
		}
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
	Filter 		=> ['POE::Filter::Block', 'BlockSize' => length $bigpacket],
	Connected	=> sub
	{
		ok(1, 'CLIENT: connected');

		$_[HEAP]->{server}->put($bigpacket);
	},
	PreConnect	=> sub
	{
		my $ctx = eval { SSLify_ContextCreate(undef, undef, 'sslv3') };
		ok(!$@, "CLIENT: SSLify_ContextCreate $@");
		my $socket = eval { Client_SSLify($_[ARG0], undef, undef, $ctx) };
		ok(!$@, "CLIENT: Client_SSLify $@");
		ok(1, 'CLIENT: SSLify_GetCipher: '. SSLify_GetCipher($socket));

		# We pray that IO::Handle is sane...
		ok( SSLify_GetSocket( $socket )->blocking == 0, 'CLIENT: SSLified socket is non-blocking?') if $^O ne 'MSWin32';

		return ($socket);
	},
	ServerInput	=> sub
	{
		my ($kernel, $heap, $line) = @_[KERNEL, HEAP, ARG0];

		if ($line eq $bigpacket) {
			## At this point, connection MUST be encrypted.
			my $cipher = SSLify_GetCipher($heap->{server}->get_output_handle);
			ok($cipher ne '(NONE)', "CLIENT: SSLify_GetCipher: $cipher");
			diag( Net::SSLeay::dump_peer_certificate( SSLify_GetSSL( $heap->{server}->get_output_handle ) ) ) if $ENV{TEST_VERBOSE};
			$replies++;
			$kernel->yield('shutdown');
		} else {
			die "Unknown line from SERVER: $line";
		}
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
) for 1 .. 10;

$poe_kernel->run();

is( $replies, 10, "Make sure we got 10 replies back!" );

done_testing;
