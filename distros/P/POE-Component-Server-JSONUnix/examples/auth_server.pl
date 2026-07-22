#!/usr/bin/env perl
use strict;
use warnings;
use v5.10;

# Demonstration of the built-in Unix-ownership user-verification system.
#
# Run the server:
#   perl -Ilib examples/auth_server.pl [/path/to/socket]
#
# Then talk to it with the companion client:
#   perl -Ilib examples/auth_client.pl
#
# Or bypass auth to see the gate in action:
#   perl -Ilib examples/client.pl whoami          # blocked — not authenticated
#   perl -Ilib examples/client.pl auth_start      # step 1: get a challenge

use POE;
use POE::Component::Server::JSONUnix;

my $socket_path = $ARGV[0] // '/tmp/jsonunix_auth.sock';

my $server = POE::Component::Server::JSONUnix->spawn(
    socket_path   => $socket_path,
    socket_mode   => 0600,
    auth_required => 1,    # block all commands until auth_verify succeeds

    commands => {
        # Returns the verified identity of the caller.
        whoami => sub {
            my ( $server, $request, $ctx ) = @_;
            return {
                uid      => $ctx->uid,
                username => $ctx->username,
            };
        },

        # Only runs if the caller is root (uid 0).
        rootonly => sub {
            my ( $server, $request, $ctx ) = @_;
            die "permission denied: root only\n" unless $ctx->uid == 0;
            return { secret => 'the roof is on fire' };
        },
    },
);

# Shut down tidily on Ctrl-C / SIGTERM.
POE::Session->create(
    inline_states => {
        _start => sub {
            $_[KERNEL]->sig( INT  => 'stop' );
            $_[KERNEL]->sig( TERM => 'stop' );
        },
        stop => sub {
            my $kernel = $_[KERNEL];
            $kernel->sig_handled;
            warn "shutting down...\n";
            $server->shutdown;
        },
    },
);

warn "listening on $socket_path  (Ctrl-C to stop)\n";
warn "try:  perl -Ilib examples/auth_client.pl\n";

$poe_kernel->run;
exit 0;
