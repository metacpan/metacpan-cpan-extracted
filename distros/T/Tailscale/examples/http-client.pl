#!/usr/bin/perl
# Demo: HTTP client over a Tailscale network.
#
# Usage: perl examples/http-client.pl <config_path> <auth_key> <host:port> [path]
#
# Connects to a host on your tailnet and makes an HTTP GET request.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Tailscale;

die "Usage: $0 <config_path> <auth_key> <host:port> [path]\n" unless @ARGV >= 3;
my ($config_path, $auth_key, $target, $path) = @ARGV;
$path //= "/";

my $ts = Tailscale->new(
    config_path => $config_path,
    auth_key    => $auth_key,
);

my $ip = $ts->ipv4_addr();
print STDERR "Tailscale IP: $ip\n";

# Parse host from target for the Host header.
my ($host) = $target =~ /^([^:]+)/;

print STDERR "Connecting to $target...\n";
my $stream = $ts->tcp_connect($target);

# Send HTTP request.
my $request = "GET $path HTTP/1.0\r\nHost: $host\r\nConnection: close\r\n\r\n";
$stream->send_all($request);

# Read response.
my $response = "";
while (defined(my $chunk = $stream->recv(4096))) {
    $response .= $chunk;
}

print $response;
$stream->close();
$ts->close();
