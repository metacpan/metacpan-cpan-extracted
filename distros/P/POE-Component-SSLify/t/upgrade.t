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

# This tests in-situ sslification ( upgrade a non-ssl socket to ssl )

use Test::FailWarnings;
use Test::More 1.001002; # new enough for sanity in done_testing()

use POE 1.267;
use POE::Component::Client::TCP;
use POE::Component::Server::TCP;
use POE::Component::SSLify qw/Client_SSLify Server_SSLify SSLify_Options SSLify_GetCipher SSLify_ContextCreate SSLify_GetSocket/;

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
		$_[KERNEL]->post(myserver => 'shutdown');
	},
	ClientInput		=> sub
	{
		my ($kernel, $heap, $line) = @_[KERNEL, HEAP, ARG0];

		if ( $line eq 'plaintext_ping' ) {
			ok(1, "SERVER: recv: $line");
			$heap->{client}->put('plaintext_pong');
			$heap->{client}->flush; # make sure we sent the pong

			# sslify it in-situ!
			eval { SSLify_Options('mylib/example.key', 'mylib/example.crt', 'sslv3') };
			eval { SSLify_Options('../mylib/example.key', '../mylib/example.crt', 'sslv3') } if ($@);
			ok(!$@, "SERVER: SSLify_Options $@");
			my $socket = eval { Server_SSLify($heap->{client}->get_output_handle) };
			ok(!$@, "SERVER: Server_SSLify $@");
			ok(1, 'SERVER: SSLify_GetCipher: '. SSLify_GetCipher($socket));

			# We pray that IO::Handle is sane...
			ok( SSLify_GetSocket( $socket )->blocking == 0, 'SERVER: SSLified socket is non-blocking?') if $^O ne 'MSWin32';

			# TODO evil code here, ha!
			# Should I ask rcaputo to add a $rw->replace_handle($socket) method?
			# if you don't do the undef and just replace it - you'll get a bad file descriptor error from POE!
			# <fh> select error: Bad file descriptor (hits=-1)
			undef $heap->{client};
			$heap->{client} = POE::Wheel::ReadWrite->new(
				Handle => $socket,
				InputEvent   => 'tcp_server_got_input',
				ErrorEvent   => 'tcp_server_got_error',
				FlushedEvent => 'tcp_server_got_flush',
			);
		} elsif ( $line eq 'ssl_ping' ) {
			ok(1, "SERVER: recv: $line");

			## At this point, connection MUST be encrypted.
			my $cipher = SSLify_GetCipher($heap->{client}->get_output_handle);
			ok($cipher ne '(NONE)', "SERVER: SSLify_GetCipher: $cipher");

			$heap->{client}->put('ssl_pong');
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

	Connected	=> sub
	{
		ok(1, 'CLIENT: connected');

		$_[HEAP]->{server}->put("plaintext_ping");
	},
	ServerInput	=> sub
	{
		my ($kernel, $heap, $line) = @_[KERNEL, HEAP, ARG0];

		if ( $line eq 'plaintext_pong' ) {
			ok(1, "CLIENT: recv: $line");

			# sslify it in-situ!
			my $ctx = eval { SSLify_ContextCreate(undef, undef, 'sslv3') };
			ok(!$@, "CLIENT: SSLify_ContextCreate $@");
			my $socket = eval { Client_SSLify($heap->{server}->get_output_handle, undef, undef, $ctx) };
			ok(!$@, "CLIENT: Client_SSLify $@");
			ok(1, 'CLIENT: SSLify_GetCipher: '. SSLify_GetCipher($socket));

			# We pray that IO::Handle is sane...
			ok( SSLify_GetSocket( $socket )->blocking == 0, 'CLIENT: SSLified socket is non-blocking?') if $^O ne 'MSWin32';

			# TODO evil code here, ha!
			# Should I ask rcaputo to add a $rw->replace_handle($socket) method?
			# if you don't do the undef and just replace it - you'll get a bad file descriptor error from POE!
			# <fh> select error: Bad file descriptor (hits=-1)
			undef $heap->{server};
			$heap->{server} = POE::Wheel::ReadWrite->new(
				Handle => $socket,
				InputEvent   => 'got_server_input',
				ErrorEvent   => 'got_server_error',
				FlushedEvent => 'got_server_flush',
			);

			# Send the ssl ping!
			$heap->{server}->put('ssl_ping');
		} elsif ( $line eq 'ssl_pong' ) {
			ok(1, "CLIENT: recv: $line");

			## At this point, connection MUST be encrypted.
			my $cipher = SSLify_GetCipher($heap->{server}->get_output_handle);
			ok($cipher ne '(NONE)', "CLIENT: SSLify_GetCipher: $cipher");

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
);

$poe_kernel->run();

done_testing;
