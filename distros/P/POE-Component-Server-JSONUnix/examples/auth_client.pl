#!/usr/bin/env perl
use strict;
use warnings;
use v5.10;

# Companion client for examples/auth_server.pl.
#
# Performs the two-step Unix-ownership verification handshake, then calls the
# authenticated "whoami" command to confirm the server knows who we are.
#
#   perl -Ilib examples/auth_client.pl [/path/to/socket]

use IO::Socket::UNIX qw(SOCK_STREAM);
use JSON::MaybeXS;
use File::Temp qw(tempfile);

my $socket_path = $ARGV[0] // '/tmp/jsonunix_auth.sock';

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

my $sock = IO::Socket::UNIX->new(
    Type => SOCK_STREAM,
    Peer => $socket_path,
) or die "cannot connect to $socket_path: $!\n";
$sock->autoflush(1);

# --- helpers ----------------------------------------------------------------

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

# --- step 1: request a challenge --------------------------------------------

warn "==> auth_start\n";
send_request( command => 'auth_start' );
my $challenge = recv_response();
die "auth_start failed: $challenge->{error}\n" if $challenge->{status} ne 'ok';

my $cookie   = $challenge->{result}{cookie};
my $temp_dir = $challenge->{result}{temp_dir};
warn "    cookie:   $cookie\n";
warn "    temp_dir: $temp_dir\n";

# --- step 2: write the cookie to a temp file --------------------------------
#
# File::Temp creates the file as the current user, so the server will see our
# real UID when it stat()s the file.

my ( $fh, $temp_path ) = tempfile( 'jsonunix_auth_XXXXXX', DIR => $temp_dir, UNLINK => 0, PERMS => 0666 );
print {$fh} $cookie;
close $fh;
warn "    wrote cookie to $temp_path\n";

# --- step 3: verify ---------------------------------------------------------

warn "==> auth_verify\n";
send_request( command => 'auth_verify', args => { path => $temp_path } );
my $verify = recv_response();
die "auth_verify failed: $verify->{error}\n" if $verify->{status} ne 'ok';

printf "    authenticated as uid=%d username=%s\n",
    $verify->{result}{uid}, $verify->{result}{username};

# --- step 4: call an authenticated command ----------------------------------

warn "==> whoami\n";
send_request( command => 'whoami' );
my $me = recv_response();
die "whoami failed: $me->{error}\n" if $me->{status} ne 'ok';

print pretty( $me->{result} );

# --- step 4: call rootonly ----------------------------------

warn "==> rootonly\n";
send_request( command => 'rootonly' );
my $me = recv_response();
die "rootonly failed: $me->{error}\n" if $me->{status} ne 'ok';

print pretty( $me->{result} );


exit 0;
