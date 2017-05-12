#!/usr/bin/perl -w
use Test::More tests => 12;

use strict;
use Config;
use LWP::UserAgent;
use HTTP::Cookies;
use URI;

ok(1, "loaded");

my $perl = $Config{'perlpath'};
$perl = $^X if $^O eq 'VMS';
system("$perl ./apache.pl exit"); # generate the conf files
system("apache/bin/apachectl start");

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
$request = HTTP::Request->new('GET', $url);
$response = $ua->simple_request($request);
ok($response, "Should get response back for $url");
is($response->code, 302, "Should be redirect");
is($response->headers->header('Location'), '/', "location is fine");

$url = "http://$hostname:$port/leon.jpg";
$request = HTTP::Request->new('GET', $url);
$response = $ua->request($request);
ok($response, "Should get response back for $url");
ok($response->is_success, "Should get successful response back");
print $response->error_as_HTML unless $response->is_success;
my $image = $response->content;
like($image, qr/JFIF/, "Should get JPEG back");

system("apache/bin/apachectl stop");
ok(1, "Should be able to kill the servers");
