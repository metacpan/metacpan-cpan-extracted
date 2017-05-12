# vim: filetype=perl ts=2 sw=2 expandtab

use strict;
use warnings;

BEGIN {
  my @proxies = grep /^http.*proxy$/i, keys %ENV;
  delete @ENV{@proxies} if @proxies;
}

use HTTP::Request;
use HTTP::Status;
use Test::More;

plan tests => 4;

use constant DEBUG => 0;

sub POE::Kernel::TRACE_EVENTS ()     { 0 }
sub POE::Kernel::TRACE_REFCNT ()     { 0 }
sub POE::Kernel::CATCH_EXCEPTIONS () { 0 }
use Test::POE::Server::TCP;
use POE qw(Filter::Stream Component::Client::HTTP);

POE::Component::Client::HTTP->spawn(
  Alias   => 'ua',
  MaxSize => 50,
  Timeout => 2,
);

POE::Session->create(
  inline_states => {
    _start             => \&client_start,
    response           => \&response_handler,
    testd_registered   => \&testd_start,
    testd_client_input => \&testd_input,
  }
);

our %responses;
POE::Kernel->run;

exit;

sub client_start {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  DEBUG and warn "client starting...\n";

  $heap->{testd} = Test::POE::Server::TCP->spawn(
    Filter  => POE::Filter::Stream->new,
    address => 'localhost',
  );
}

sub testd_start {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  my $port = $heap->{testd}->port;

  $kernel->post(
    ua => request => response =>
    HTTP::Request->new('GET', "http://localhost:$port/content_length")
  );

  $kernel->post(
    ua => request => response =>
    HTTP::Request->new('GET', "http://localhost:$port/no_length")
  );

  $heap->{query_count} = 2;
}

sub testd_input {
  my ($kernel, $heap, $id, $input) = @_[KERNEL, HEAP, ARG0, ARG1];

  my $content_length_data = <<'EOF';
HTTP/1.1 200 OK
Content-Length: 60

123456789
123456789
123456789
123456789
123456789
123456789
EOF

  my $no_content_length_data = <<'EOF';
HTTP/1.1 200 OK

123456789
123456789
123456789
123456789
123456789
123456789
EOF

  if ($input =~ /(?:content_length)/) {
    pass("got expected content-length request");
    $heap->{testd}->send_to_client($id, $content_length_data);
  }
  elsif ($input =~ /(?:no_length)/) {
    pass("got expected no-content-length request");
    $heap->{testd}->send_to_client($id, $no_content_length_data);
  }
  else {
    BAIL_OUT("got a request that isn't even supposed to exist");
  }
}

sub response_handler {
  my $heap     = $_[HEAP];
  my $response = $_[ARG1][0];
  my $request  = $_[ARG0][0];

  my $path = $request->uri->path;
  if ($path eq '/content_length') {
    is($response->code, 406, 'content-length triggered 406');
  }
  elsif ($path eq '/no_length') {
    is($response->code, 406, 'length(content) triggered 406');
  }

  return if --$heap->{query_count};

  $heap->{testd}->shutdown();
  $_[KERNEL]->post( ua => 'shutdown' );
}
