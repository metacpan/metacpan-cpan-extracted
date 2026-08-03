#!/usr/bin/env perl
use strict;
use warnings;
use v5.10;

# Companion client for examples/auth_server.pl demonstrating the kernel
# peer-credential authentication path -- the one that needs NO cookie file.
#
# On Linux, FreeBSD, macOS, and the other supported BSDs the server knows our
# UID straight from the socket, so the whole handshake is: ask auth_start
# whether peercred is on offer, then call auth_verify with no arguments. No
# temp file is ever created. This mirrors what a non-Perl client would do on
# the wire.
#
#   perl -Ilib examples/auth_peercred_client.pl [/path/to/socket]

use IO::Socket::UNIX qw(SOCK_STREAM);
use JSON::MaybeXS;

my $socket_path = $ARGV[0] // '/tmp/jsonunix_auth.sock';

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

my $sock = IO::Socket::UNIX->new(
    Type => SOCK_STREAM,
    Peer => $socket_path,
) or die "cannot connect to $socket_path: $!\n";
$sock->autoflush(1);

sub send_request {
    my (%req) = @_;
    print {$sock} $json->encode( \%req ), "\n";
}

sub recv_response {
    my $line = readline $sock;
    die "server closed connection\n" unless defined $line;
    return $json->decode($line);
}

sub pretty { JSON::MaybeXS->new( utf8 => 1, canonical => 1, pretty => 1 )->encode(shift) }

# --- step 1: does the server offer kernel peer credentials? -----------------

warn "==> auth_start\n";
send_request( command => 'auth_start' );
my $start = recv_response();
die "auth_start failed: $start->{error}\n" if $start->{status} ne 'ok';

unless ( $start->{result}{peercred} ) {
    die "this server is not offering peercred auth on this platform;\n"
        . "use examples/auth_client.pl for the cookie-file challenge instead.\n";
}
warn "    server offers peercred -- no file needed\n";

# --- step 2: verify with no path; the kernel supplies our uid ---------------

warn "==> auth_verify (no args)\n";
send_request( command => 'auth_verify' );
my $verify = recv_response();
die "auth_verify failed: $verify->{error}\n" if $verify->{status} ne 'ok';

printf "    authenticated as uid=%d username=%s\n",
    $verify->{result}{uid}, $verify->{result}{username};

# --- step 3: call an authenticated command ----------------------------------

warn "==> whoami\n";
send_request( command => 'whoami' );
my $me = recv_response();
die "whoami failed: $me->{error}\n" if $me->{status} ne 'ok';

print pretty( $me->{result} );

exit 0;
