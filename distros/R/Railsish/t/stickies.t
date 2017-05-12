#!/usr/bin/env perl
# ABSTRACT:
#   This is a whitebox test to see if "notice_stickie" pushes
#   stickies into session.

use strict;
use warnings;
use Moose ();

use Test::More tests => 2;

my $STICKIE_TEXT = "Foo" . time;

package FooController;
use Railsish::Controller;

sub index {
    notice_stickie($STICKIE_TEXT)
}

package main;

use HTTP::Engine;
use HTTP::Request;
use HTTP::Engine::Response;
use Railsish::Router;
use Railsish::Dispatcher;
use CGI::Cookie;

Railsish::Router->draw(
    sub {
        my ($map) = @_;
        $map->connect("", controller => "foo");
    }
);

my $engine = HTTP::Engine->new(
    interface => {
        module => "Test",
        request_handler => sub {
            Railsish::Dispatcher->dispatch(@_);
        }
    }
);

use YAML;
use Crypt::CBC;
use MIME::Base64;
use JSON::XS;

my $response = $engine->run(HTTP::Request->new(GET => "http://localhost/"), connection_info => { request_uri => "/" });

my $session_cookie = CGI::Cookie->parse($response->header('Set-Cookie'))->{_railsish_session};

# diag YAML::Dump($session_cookie);

# Decipher session from cookie.
my $cipher = Crypt::CBC->new(-key => "railsish", -cipher => "Rijndael");
my $ciphertext_base64   = $session_cookie->value;
my $ciphertext_unbase64 = decode_base64($ciphertext_base64);
my $json = $cipher->decrypt($ciphertext_unbase64);
my $session = decode_json($json);

my @notice_stickies = @{$session->{notice_stickies}};
ok(@notice_stickies > 0);
is_deeply(\@notice_stickies, [ { text => $STICKIE_TEXT }]);
