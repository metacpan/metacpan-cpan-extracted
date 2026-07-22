#!/usr/bin/env perl
use strict;
use warnings;
use v5.10;

# A minimal blocking client for the demonstration server. Uses only core
# modules (no POE needed on the client side).
#
#   perl -Ilib examples/client.pl <command> [json-args] [id]
#
# Examples:
#   perl -Ilib examples/client.pl ping
#   perl -Ilib examples/client.pl add '{"numbers":[1,2,3,4]}'
#   perl -Ilib examples/client.pl divide '{"numerator":10,"denominator":0}'
#   perl -Ilib examples/client.pl slow
#
# The socket path comes from $JSONUNIX_SOCK, or defaults to /tmp/jsonunix.sock.

use Socket qw(SOCK_STREAM);
use IO::Socket::UNIX;
use JSON::MaybeXS;

my $socket_path = $ENV{JSONUNIX_SOCK} // '/tmp/jsonunix.sock';

my ( $command, $args_json, $id ) = @ARGV;
die "usage: $0 <command> [json-args] [id]\n" unless defined $command;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

my %request = ( command => $command );
$request{args} = $json->decode($args_json) if defined $args_json;
$request{id}   = $id                        if defined $id;

my $sock = IO::Socket::UNIX->new(
    Type => SOCK_STREAM,
    Peer => $socket_path,
) or die "cannot connect to $socket_path: $!\n";
$sock->autoflush(1);

print {$sock} $json->encode( \%request ), "\n";

my $line = readline $sock;
die "server closed the connection without replying\n" unless defined $line;

my $response = $json->decode($line);

# Pretty-print the response for human consumption.
my $pretty = JSON::MaybeXS->new( utf8 => 1, canonical => 1, pretty => 1 );
print $pretty->encode($response);

exit( ( $response->{status} // '' ) eq 'ok' ? 0 : 1 );
