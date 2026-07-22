#!/usr/bin/env perl
use strict;
use warnings;
use v5.10;

# Companion client for examples/permissions_server.pl. Walks through the
# server's permission policy step by step, showing what is allowed, what is
# denied, and the machine-readable 'code' field that says why.
#
#   perl -Ilib examples/permissions_client.pl [/path/to/socket]

use POE::Component::Server::JSONUnix::BlockingClient;
use JSON::MaybeXS;

my $socket_path = $ARGV[0] // '/tmp/jsonunix_perms.sock';

$| = 1;    # keep results interleaved with the step headers on stderr

sub pretty { JSON::MaybeXS->new( utf8 => 1, canonical => 1, pretty => 1 )->encode(shift) }

sub show {
    my ($response) = @_;
    if ( $response->{status} eq 'ok' ) {
        print pretty( $response->{result} );
    } else {
        printf "    refused (code=%s): %s\n",
            $response->{code} // 'none', $response->{error};
    }
    return;
}

my $client = POE::Component::Server::JSONUnix::BlockingClient->new(
    socket_path => $socket_path,
    timeout     => 10,
);

# --- before authenticating ---------------------------------------------------

warn "==> status  (rule: 'allow' -- works for anyone, even unauthenticated)\n";
show( $client->call( command => 'status' ) );

warn "==> reload  (rule: group -- but we have not authenticated yet)\n";
show( $client->call( command => 'reload' ) );

# --- authenticate -------------------------------------------------------------

warn "==> authenticate\n";
my $auth = $client->authenticate;
die "authentication failed: $auth->{error}\n" if $auth->{status} ne 'ok';
printf "    authenticated as uid=%d username=%s\n", $client->uid, $client->username;
printf "    groups: %s\n", join( ', ', @{ $client->groups } );

# --- after authenticating ------------------------------------------------------

warn "==> commands  (only lists what we may actually run)\n";
show( $client->call( command => 'commands' ) );

warn "==> permissions_info  (ctx->groups / in_group / may, server side)\n";
show( $client->call( command => 'permissions_info' ) );

warn "==> greet  (no rule of its own: the '%DEFAULT%' user rule applies)\n";
show( $client->call( command => 'greet' ) );

warn "==> reload  (group rule; secondary group memberships count)\n";
show( $client->call( command => 'reload' ) );

warn "==> danger  (check coderef: refused without args.dry_run...)\n";
show( $client->call( command => 'danger' ) );

warn "==> danger with dry_run  (...allowed with it)\n";
show( $client->call( command => 'danger', args => { dry_run => 1 } ) );

warn "==> shutdown_server  (rule: root only -- denied unless you ran this as root)\n";
show( $client->call( command => 'shutdown_server' ) );

$client->disconnect;
exit 0;
