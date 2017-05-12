#!/usr/bin/perl
# vim: filetype=perl ts=2 sw=2 expandtab

# Test gzip'd content encoding.

use warnings;
use strict;

BEGIN {
  my @proxies = grep /^http.*proxy$/i, keys %ENV;
  delete @ENV{@proxies} if @proxies;
}

use IO::Socket::INET;
use Socket '$CRLF', '$LF', '$CR';
use HTTP::Request::Common 'GET';

sub DEBUG () { 0 }

# The number of tests must match scalar(@tests).
use Test::More;

use POE;
use POE::Component::Client::HTTP;
use POE::Component::Server::TCP;

use Net::HTTP::Methods;

if (
  eval { Net::HTTP::Methods::zlib_ok() } or
  eval { Net::HTTP::Methods::gunzip_ok() }
) {
  plan tests => 1;
}
else {
  plan skip_all => 'Compress::Zlib no present';
}

# eval this so that if it's NOT present we don't barf before we can
# call zlib_ok()
eval "use Compress::Zlib";

my $test_number = 0;

my @server_ports;

# A list of test responses, each paired with a subroutine to check
# whether the response was parsed.
# use YAML;

my $original_content = <<DONE;
<html>
 <head>
  <title>Sample Document</title>
 </head>
 <body>
  Sample content
 </body>
</html>
DONE

## content compression lifted from Apache::Dynagzip
## this is functionally equivalent to mod_gzip, etc.
## so we have a "real-world" piece of encoded content

my $gzipped_content;

GZIP: {
  use constant MAGIC1  => 0x1f ;
  use constant MAGIC2  => 0x8b ;
  use constant OSCODE  => 3 ;
  use constant MIN_HDR_SIZE => 10 ; # minimum gzip header size

  use bytes;

  # Create the first outgoing portion of the content:

  my $gzipHeader = pack(
    "C" . MIN_HDR_SIZE, MAGIC1, MAGIC2, Z_DEFLATED(), 0,0,0,0,0,0, OSCODE
  );
  $gzipped_content = $gzipHeader;

  my $gzip_handler = deflateInit(
    -Level      => Z_BEST_COMPRESSION(),
    -WindowBits => - MAX_WBITS(),
  );

  $_ = $original_content;

  my ($out, $status) = $gzip_handler->deflate(\$_);
  unless (length($out)) {
    ($out, $status) = $gzip_handler->flush();
  }

  $gzipped_content .= $out;

  # almost the same thing, but I wanted to go thru all the hoops:
  if (0) {
    $_ = $original_content;
    $gzipped_content = Compress::Zlib::memGzip($_);
  }
}

my @tests = (
  # Gzipped content decoded correctly.
  [
    (
      "HTTP/1.1 200 OK$CRLF" .
      "Connection: close$CRLF" .
      "Content-Encoding: gzip$CRLF" .
      "Content-type: text/plain$CRLF" .
      $CRLF .
      "$gzipped_content$CRLF"
    ),
    sub {
      my $response = shift;

      ok(
        $response->code() == 200 &&
        $response->decoded_content eq $original_content,
        "gzip encoded transfers decode correctly"
      );
    },
  ],
);

# We are testing against a localhost server.
# Don't proxy, because localhost takes on new meaning.
BEGIN {
  delete $ENV{HTTP_PROXY};
}

# Spawn one server per test response.
{
  foreach (@tests) {
    POE::Component::Server::TCP->new(
      Alias               => "server_$_",
      Address             => "127.0.0.1",
      Port                => 0,
      Started             => \&register_port,
      ClientInputFilter   => "POE::Filter::Line",
      ClientOutputFilter  => "POE::Filter::Stream",
      ClientInput         => \&parse_next_request,
    );
  }

  sub register_port {
    push(
      @server_ports,
      (sockaddr_in($_[HEAP]->{listener}->getsockname()))[0]
    );
  }

  sub parse_next_request {
    my $input = $_[ARG0];

    DEBUG and diag "got line: [$input]";
    return if $input ne "";

    my $response = $tests[$test_number][0];
    $_[HEAP]->{client}->put($response);

    $response =~ s/$CRLF/{CRLF}/g;
    DEBUG and diag "sending: [$response]";

    $_[KERNEL]->yield("shutdown");
  }
}


# Spawn the HTTP user-agent component.
POE::Component::Client::HTTP->spawn();

# Create a client session to drive the HTTP component.
POE::Session->create(
  inline_states => {
    _start => sub {
      $_[KERNEL]->yield("run_next_test");
    },
    run_next_test => sub {
      my $port    = $server_ports[$test_number];
      $_[KERNEL]->post(
        weeble => request => response =>
        GET "http://127.0.0.1:${port}/"
      );
    },
    response => sub {
      my $response = $_[ARG1][0];
      my $test     = $tests[$test_number][1];
      $test->($response);

      $_[KERNEL]->post("server_$tests[$test_number]", "shutdown");

      if (++$test_number < @tests) {
        $_[KERNEL]->yield("run_next_test");
      }
      else {
        $_[KERNEL]->post("weeble", "shutdown");
      }
    },
    _stop => sub { undef },
  }
);

POE::Kernel->run();
exit;
