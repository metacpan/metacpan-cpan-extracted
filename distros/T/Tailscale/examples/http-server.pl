#!/usr/bin/perl
# Demo: HTTP server on a Tailscale network.
#
# Usage: perl examples/http-server.pl <config_path> <auth_key>
#
# Starts an HTTP server on port 8080 on your tailnet IP.
# Test with: curl http://<tailscale-ip>:8080/

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Tailscale;
use Tailscale::HttpServer;
use HTTP::Response;

die "Usage: $0 <config_path> <auth_key>\n" unless @ARGV >= 2;
my ($config_path, $auth_key) = @ARGV;

my $ts = Tailscale->new(
    config_path => $config_path,
    auth_key    => $auth_key,
);

my $ip = $ts->ipv4_addr();
print "Tailscale IP: $ip\n";

my $httpd = Tailscale::HttpServer->new(tailscale => $ts, port => 8080);

$httpd->run(sub {
    my ($req) = @_;
    print "Request: " . $req->method . " " . $req->uri . "\n";

    my $res = HTTP::Response->new(200);
    $res->header('Content-Type' => 'text/plain');
    $res->content("Hello from Perl on Tailscale!\n\nYou requested: " . $req->uri . "\n");
    return $res;
});
