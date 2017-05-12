#!/usr/bin/perl
# vim: ts=2 sw=2 filetype=perl expandtab

# This tests for a case where a redirect and incorrect content-length
# will cause two responses to be generated for one request.

use warnings;
use strict;

use IO::Socket::INET;
use Socket '$CRLF';
use HTTP::Request::Common 'GET';

sub POE_ASSERT_DEFAULT() { 1 }
sub DEBUG () { 0 }

use Test::More tests => 3;

use POE;
use POE::Component::Client::HTTP;
use POE::Component::Server::TCP;

my $port;
my $response;
sub fix_response { 
  $response =
    "HTTP/1.1 302 Moved$CRLF" .
    "Connection: close$CRLF" .
    "Content-length: 0$CRLF" .
    "Content-type: text/plain$CRLF" .
    "Location: http://127.0.0.1:${port}$CRLF" .
    $CRLF .
    "Not really content$CRLF"
}

# Spawn one server per test response.
{
  POE::Component::Server::TCP->new(
    Alias               => "tcp_server",
    Address             => "127.0.0.1",
    Port                => 0,
    Started             => \&register_port,
    ClientInputFilter   => "POE::Filter::Line",
    ClientOutputFilter  => "POE::Filter::Stream",
    ClientInput         => \&parse_next_request,
  );

  sub register_port {
    $port = (sockaddr_in($_[HEAP]->{listener}->getsockname()))[0];
    fix_response();
  }

  sub parse_next_request {
    my $input = $_[ARG0];

    DEBUG and diag "got line: [$input]";
    return if $input ne "";

    $_[HEAP]->{client}->put($response);

    DEBUG and diag "sending";
    $_[KERNEL]->yield("shutdown");
  }
}

# Spawn the HTTP user-agent component.
POE::Component::Client::HTTP->spawn( FollowRedirects => 1 );

# Create a client session to drive the HTTP component.
POE::Session->create(
  inline_states => {
    _start => sub {
      $_[KERNEL]->post(
        weeble => request => response =>
        GET "http://127.0.0.1:${port}/"
      );
    },
    response => sub {
      my $response = $_[ARG1][0];
      my $content = $response->content();

      ++$_[HEAP]->{response_num};

      $content =~ s/\x0D/{CR}/g;
      $content =~ s/\x0A/{LF}/g;

      pass "got a response, content = ($content)";

      ok(defined $response->request, "response has corresponding request object set");

      $_[KERNEL]->delay(dummy => 1.0); # so we can get any belated stupidity
    },
    dummy=> sub {
      $_[KERNEL]->post("tcp_server", "shutdown");
      $_[KERNEL]->post("weeble", "shutdown");
    },
    _stop => sub {
      is(
        1, $_[HEAP]->{response_num},
        'correct number of responses recieved'
      );
    },
  }
);

POE::Kernel->run();
exit;
