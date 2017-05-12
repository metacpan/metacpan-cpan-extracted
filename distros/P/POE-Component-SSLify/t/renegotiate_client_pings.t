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

# Thanks to ASCENT for this test!
# This test adds renegotiation to the connection from client-side
# Since this is not supported on all platforms, it's marked TODO and adds custom logic
# to make sure it doesn't FAIL if it's not supported.

use Test::FailWarnings;
use Test::More 1.001002; # new enough for sanity in done_testing()

use POE 1.267;
use POE::Component::Client::TCP;
use POE::Component::Server::TCP;
use POE::Component::SSLify qw/Client_SSLify Server_SSLify SSLify_Options SSLify_GetCipher SSLify_ContextCreate SSLify_GetSocket SSLify_GetSSL/;
use Net::SSLeay qw/ERROR_WANT_READ ERROR_WANT_WRITE/;

# TODO rewrite this to use Test::POE::Server::TCP and stuff :)

my $port;
my $server_ping2;
my $client_ping2;

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
		$_[KERNEL]->post(myserver => 'shutdown');
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
		my ($kernel, $heap, $request) = @_[KERNEL, HEAP, ARG0];

		## At this point, connection MUST be encrypted.
		my $cipher = SSLify_GetCipher($heap->{client}->get_output_handle);
		ok($cipher ne '(NONE)', "SERVER: SSLify_GetCipher: $cipher");

		if ($request eq 'ping')
		{
			ok(1, "SERVER: recv: $request");
			$heap->{client}->put("pong");
		}
		elsif ($request eq 'ping2')
		{
			ok(1, "SERVER: recv: $request");
			$server_ping2++;
			$heap->{client}->put("pong2");
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

	Connected	=> sub
	{
		ok(1, 'CLIENT: connected');

		$_[HEAP]->{server}->put("ping");
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

		## At this point, connection MUST be encrypted.
		my $cipher = SSLify_GetCipher($heap->{server}->get_output_handle);
		ok($cipher ne '(NONE)', "CLIENT: SSLify_GetCipher: $cipher");

		if ($line eq 'pong')
		{
			ok(1, "CLIENT: recv: $line");

			# Skip 2 Net::SSLeay::renegotiate() tests on FreeBSD because of
			# http://security.freebsd.org/advisories/FreeBSD-SA-09:15.ssl.asc
			TODO: {
				local $TODO = "Net::SSLeay::renegotiate() does not work on all platforms";

				## Force SSL renegotiation
				my $ssl = SSLify_GetSSL( $heap->{server}->get_output_handle );
				my $reneg_num = Net::SSLeay::num_renegotiations($ssl);

				ok(1 == Net::SSLeay::renegotiate($ssl), 'CLIENT: SSL renegotiation');
				my $handshake = Net::SSLeay::do_handshake($ssl);
				my $err = Net::SSLeay::get_error($ssl, $handshake);

				## 1 == Successful handshake, ERROR_WANT_(READ|WRITE) == non-blocking.
				ok($handshake == 1 || $err == ERROR_WANT_READ || $err == ERROR_WANT_WRITE, 'CLIENT: SSL handshake');
				ok($reneg_num < Net::SSLeay::num_renegotiations($ssl), 'CLIENT: Increased number of negotiations');
			}

			$heap->{server}->put('ping2');
		}

		elsif ($line eq 'pong2')
		{
			ok(1, "CLIENT: recv: $line");
			$client_ping2++;
			$kernel->yield('shutdown');
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
);

$poe_kernel->run();

# Add extra pass() to make the test harness happy if renegotiate did not work
if ( ! $server_ping2 ) {
	local $TODO = "Net::SSLeay::renegotiate() does not work on all platforms";
	fail( "SERVER: Failed SSL renegotiation" );
}
if ( ! $client_ping2 ) {
	local $TODO = "Net::SSLeay::renegotiate() does not work on all platforms";
	fail( "CLIENT: Failed SSL renegotiation" );
}
if ( ! $server_ping2 or ! $client_ping2 ) {
	diag( "WARNING: Your platform/SSL library does not support renegotiation of the SSL socket." );
	diag( "This test harness detected that trying to renegotiate resulted in a disconnected socket." );
	diag( "POE::Component::SSLify will work on your system, but please do not attempt a SSL renegotiate." );
	diag( "Please talk with the author to figure out if this issue can be worked around, thank you!" );
}

done_testing;
