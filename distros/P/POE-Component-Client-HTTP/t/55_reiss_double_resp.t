#!/usr/bin/perl
# vim: ts=2 sw=2 filetype=perl expandtab

# This tests cases where a socket it reused in spite of
# the entire response not having been read off the socket.

use warnings;
use strict;

BEGIN {
  my @proxies = grep /^http.*proxy$/i, keys %ENV;
  delete @ENV{@proxies} if @proxies;
}

use IO::Socket::INET;
use Socket '$CRLF';
use HTTP::Request::Common 'GET';

sub POE_ASSERT_DEFAULT () { 1 }
sub DEBUG ()              { 0 }

use Test::More tests => 9;

use POE;
use POE::Component::Client::HTTP;
use POE::Component::Server::TCP;

my $port;

my @responses;

my @cases = (
  {
    number => 1,
    tries_left => 1,
    request => sub {
      [
        "HTTP/1.1 302 Moved$CRLF"
          . "Location: http://127.0.0.1:${port}/stuff$CRLF"
          . "Connection: close$CRLF"
          . "Content-type: text/plain$CRLF"
          . $CRLF
          . "Line 1 of the redirect",
        "Line 2 of the redirect",
        "Line 3 of the redirect",
        "",    # keep the connection open, maybe
        "",
        "",
        "",
      ];
    },
  },
  {
    number => 2,
    tries_left => 2,
    request => sub {
      [
        "HTTP/1.1 200 OK$CRLF"
          . "Connection: close$CRLF"
          . "Content-type: text/plain$CRLF$CRLF"
          . ("Too Much" x 64),
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "should not appear",
        "should not appear",
        "should not appear",
        "should not appear",
        "should not appear"
      ];
    },
  }
);

my $case = shift @cases;
spawn_server();

sub set_responses {
  # Sub call to create a new copy each time.
  @responses = $case->{request}->();
}

### Server.

my $server_alias;

sub spawn_server {
  $server_alias = "server_$case->{number}";
  POE::Component::Server::TCP->new(
    Alias              => $server_alias,
    Address            => "127.0.0.1",
    Port               => 0,
    Started            => \&register_port,
    ClientConnected    => \&connected,
    ClientInputFilter  => "POE::Filter::Line",
    ClientOutputFilter => "POE::Filter::Stream",
    ClientInput        => \&parse_next_request,
    Concurrency        => 1,
    InlineStates       => {next_part => \&next_part},
  );
}

sub connected {
  DEBUG and diag "server: received new connection - shutting down";
  $_[KERNEL]->post($server_alias => 'shutdown');
}

sub register_port {
  $port = (sockaddr_in($_[HEAP]->{listener}->getsockname()))[0];
  set_responses();
}

sub next_part {
  my $left = $_[ARG0];
  my $next = shift @$left;

  if (!$_[HEAP]->{client}) {
    $_[KERNEL]->yield('shutdown');
    return;
  }

  $_[HEAP]->{client}->put($next);

  DEBUG and diag "server: sent [$next]\n";

  if (@$left) {
    $_[KERNEL]->delay(next_part => 0.1 => $left);
  }
  else {
    $_[KERNEL]->yield('shutdown');
  }
}

sub parse_next_request {
  my $input = $_[ARG0];

  DEBUG and diag "server: received [$input]";
  return if $input ne "";

  if (!$_[HEAP]->{in_progress}++) {
    my $response = pop @responses;
    $_[KERNEL]->yield(next_part => [@$response]);
  }
}

### CLIENT

# Spawn the HTTP user-agent component.
POE::Component::Client::HTTP->spawn(
  FollowRedirects => 3,
  MaxSize         => 512,
  Timeout         => 2,
);

# Create a client session to drive the HTTP component.
POE::Session->create(
  inline_states => {
    _start => sub {
      $_[KERNEL]->yield('begin');
    },
    begin => sub {
      # Request a redirect.
      $_[KERNEL]->post(
        weeble => request => response => GET "http://127.0.0.1:${port}/"
      );
    },
    response => sub {
      my $response = $_[ARG1][0];
      my $content  = $response->content();

      $content =~ s/\x0D/{CR}/g;
      $content =~ s/\x0A/{LF}/g;

      pass "got a response, content = ($content)";

      ok(
        defined $response->request,
        "response has corresponding request object set"
      );

      if ($case->{number} == 1) {
        # Case 1 redirects to a dead port.  We should get a 400.
        ok(
          ($response->code == 500) || ($response->code == 408),
          "case 1 redirect to dead server returns 500"
        );
      }
      elsif ($case->{number} == 2) {
        if ($case->{tries_left} == 2) {
          # Case 2.2 tests whether excess content triggers socket reuse.
          is($response->code, 406, "case 2.2 response is too long");
        }
        elsif ($case->{tries_left} == 1) {
          # Case 2.1 redirects to a dead port.  We should get a 400.
          is($response->code, 500, "case 2.1 redirect to dead server = 500");
        }
      }

      $case->{tries_left}--;

      # Somehow we got too many responses.
      if ($case->{tries_left} < 0) {
        fail("too many responses");
        return;
      }

      # There are tries remaining in this case.  Try again.
      if ($case->{tries_left}) {
        DEBUG and diag "client: requests left in this set";
        $_[KERNEL]->delay('begin' => 0.6);
        return;
      }

      # We're done if no cases remain.
      unless (@cases) {
        $_[KERNEL]->post(weeble => 'shutdown');
        return;
      }

      # Next case, please.
      $case = shift @cases;
      spawn_server();
      $_[KERNEL]->yield('begin');
    },
  }
);

POE::Kernel->run();
exit;
