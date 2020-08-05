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
use POE::Component::TLSify qw/Client_TLSify Server_TLSify TLSify_GetCipher TLSify_GetSocket/;

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
    my $args = {
      SSL_cert_file => 'mylib/ircd.crt',
      SSL_key_file  => 'mylib/ircd.key',
    };

		my $socket = eval { Server_TLSify( $_[ARG0], $args, sub {
			my( $socket, $status, $errval ) = @_;

			pass( "SERVER: Got callback hook" );
			is( $status, 1, "SERVER: Status received from callback is OK" );

			## At this point, connection MUST be encrypted.
			my $cipher = TLSify_GetCipher($socket);
			#ok($cipher ne '(NONE)', "SERVER: TLSify_GetCipher: $cipher");
		} ) };
		ok(!$@, "SERVER: Server_TLSify $@");

		return ($socket);
	},
	ClientInput		=> sub
	{
		my ($kernel, $heap, $line) = @_[KERNEL, HEAP, ARG0];

		if ( $line ne 'ping' ) {
			die "Unknown line from CLIENT: $line";
		} else {
			ok(1, "SERVER: recv: $line");
			$_[HEAP]->{client}->put("pong");
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

  #SessionParams => [ options => { debug => 1, trace => 1 } ],
  InlineStates => {
    _connected => sub {
        my ($kernel,$heap) = @_[KERNEL,HEAP];
        my( $socket, $status, $errval ) = @{ $_[ARG1] };
			  pass( "CLIENT: Got callback hook status" );
			  is( $status, 1, "CLIENT: Status received from callback is OK" );

			  ## At this point, connection MUST be encrypted.
			  my $cipher = TLSify_GetCipher($socket);
			  ok($cipher ne '(NONE)', "CLIENT: TLSify_GetCipher: $cipher");
		    $heap->{server}->put("ping");
    },
  },

	Connected	=> sub
	{
		ok(1, 'CLIENT: connected');
		#$_[HEAP]->{server}->put("ping");
	},
	PreConnect	=> sub
	{
    require IO::Socket::SSL;
    my $args = { SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE() };
    my $postback = $_[SESSION]->postback('_connected');
		my $socket = eval { Client_TLSify($_[ARG0], $args, sub { $postback->(@_) } ) };
		ok(!$@, "CLIENT: Client_TLSify $@");

		return ($socket);
	},
	ServerInput	=> sub
	{
		my ($kernel, $heap, $line) = @_[KERNEL, HEAP, ARG0];

		if ( $line ne 'pong' ) {
			die "Unknown line from CLIENT: $line";
		} else {
			ok(1, "CLIENT: recv: $line");
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

done_testing;
