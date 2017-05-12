#!/usr/bin/perl -w
use Test::More tests => 12;

use strict;
no warnings 'once';
use Config;
use LWP::UserAgent;
use HTTP::Cookies;
use URI;

ok(1, "loaded");

my $perl = $^X;

my $pid = open(DAEMON, "$perl ./apache.pl |");
die "Can't exec: $!" unless defined $pid;

my $port = 7500 + $<; # give every user a different port
my $hostname = 'localhost'; # hostname;
my $url = "http://$hostname:$port/";

my $ua = LWP::UserAgent->new(cookie_jar => HTTP::Cookies->new());

# Wait for the server to start working
while (1) {
  sleep 1;
  my $request = HTTP::Request->new('GET', $url);
  my $response = $ua->request($request);
  last if $response->is_success;
}
ok(1, "should get server up ok");

my $request = HTTP::Request->new('GET', $url);
my $response = $ua->request($request);
ok($response, "Should get response back for $url");
ok($response->is_success, "Should get successful response back");
print $response->error_as_HTML unless $response->is_success;
my $html = $response->content;
ok($html, "Should get some HTML back");

$url = "http://$hostname:$port/redirect/";
my $ua = LWP::UserAgent->new(cookie_jar => HTTP::Cookies->new());
my $request = HTTP::Request->new('GET', $url);
my $response = $ua->simple_request($request);
ok($response, "Should get response back for $url");
is($response->code, 302, "Should be redirect");
is($response->headers->header('Location'), '/', "location is fine");

$url = "http://$hostname:$port/leon.jpg";
my $ua = LWP::UserAgent->new(cookie_jar => HTTP::Cookies->new());
my $request = HTTP::Request->new('GET', $url);
my $response = $ua->request($request);
ok($response, "Should get response back for $url");
ok($response->is_success, "Should get successful response back");
print $response->error_as_HTML unless $response->is_success;
my $image = $response->content;
like($image, qr/JFIF/, "Should get JPEG back");

# Kill the OpenFrame::Server::HTTP servers
kill 2, $pid;
ok(1, "Should be able to kill the servers");
