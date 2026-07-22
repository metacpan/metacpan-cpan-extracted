#!/usr/bin/env perl
use strict;
use warnings;
use v5.10;

# Companion client for examples/auth_server.pl, using the POE-based
# POE::Component::Server::JSONUnix::Client instead of a blocking socket.
#
# Connects, performs the Unix-ownership verification handshake automatically
# (auto_auth), then calls the authenticated "whoami" command.
#
#   perl -Ilib examples/poe_auth_client.pl [/path/to/socket]

use POE;
use POE::Component::Server::JSONUnix::Client;
use JSON::MaybeXS;

my $socket_path = $ARGV[0] // '/tmp/jsonunix_auth.sock';

sub pretty { JSON::MaybeXS->new( utf8 => 1, canonical => 1, pretty => 1 )->encode(shift) }

my $client;
$client = POE::Component::Server::JSONUnix::Client->spawn(
	socket_path     => $socket_path,
	auto_auth       => 1,
	request_timeout => 10,

	on_connect => sub { warn "==> connected to $socket_path\n" },

	on_auth => sub {
		my ( $c, $response ) = @_;
		die "authentication failed: $response->{error}\n"
			if $response->{status} ne 'ok';

		printf "    authenticated as uid=%d username=%s\n",
			$c->uid, $c->username;

		warn "==> whoami\n";
		$c->call(
			command  => 'whoami',
			callback => sub {
				my ($whoami) = @_;
				die "whoami failed: $whoami->{error}\n"
					if $whoami->{status} ne 'ok';
				print pretty( $whoami->{result} );
				$c->shutdown;
			},
		);
	},

	on_disconnect => sub {
		my ( $c, $reason ) = @_;
		warn "==> disconnected: $reason\n";
	},

	on_error => sub {
		my ( $operation, $errnum, $errstr ) = @_;
		die "error during $operation: $errstr\n";
	},
);

$poe_kernel->run;
exit 0;
