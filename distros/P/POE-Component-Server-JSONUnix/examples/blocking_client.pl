#!/usr/bin/env perl
use strict;
use warnings;
use v5.10;

# Demonstration of POE::Component::Server::JSONUnix::BlockingClient, the
# simple non-POE client. Run examples/auth_server.pl first, then:
#
#   perl -Ilib examples/blocking_client.pl [/path/to/socket]

use POE::Component::Server::JSONUnix::BlockingClient;
use JSON::MaybeXS;

my $socket_path = $ARGV[0] // '/tmp/jsonunix_auth.sock';

sub pretty { JSON::MaybeXS->new( utf8 => 1, canonical => 1, pretty => 1 )->encode(shift) }

my $client = POE::Component::Server::JSONUnix::BlockingClient->new(
    socket_path => $socket_path,
    timeout     => 10,
);

# The server was started with auth_required, so authenticate first.
warn "==> authenticate\n";
my $auth = $client->authenticate;
die "authentication failed: $auth->{error}\n" if $auth->{status} ne 'ok';
printf "    authenticated as uid=%d username=%s\n", $client->uid, $client->username;

warn "==> whoami\n";
my $me = $client->call( command => 'whoami' );
die "whoami failed: $me->{error}\n" if $me->{status} ne 'ok';
print pretty( $me->{result} );

warn "==> commands\n";
my $commands = $client->call( command => 'commands' );
die "commands failed: $commands->{error}\n" if $commands->{status} ne 'ok';
print pretty( $commands->{result} );

$client->disconnect;
exit 0;
